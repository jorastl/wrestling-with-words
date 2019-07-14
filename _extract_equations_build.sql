 CREATE SCHEMA www
  AUTHORIZATION postgres;

 --drop table www.texts;
 create table www.texts (
    id serial not null primary key,
    name varchar (255) not null,
    text text not null,
    learned boolean not null default false
 ); 
  
 --drop table www.equation;
 create table www.equation (
    id bigserial not null primary key,
    label varchar (255) not null,
    equation text not null,
    count integer default 0
 );
 
 --drop sequence www.labelseq;
 create sequence www.labelseq start 1;
 
  
  
 create or replace function www.extract_equations(ptext text) returns text
language plpgsql
as $$
declare

    named_formula_indicator CONSTANT VARCHAR := '\begin{equation}';
    named_formula_ending    CONSTANT VARCHAR := '\end{equation}';
    
    equation    text;
    rest        text;
    v_label       varchar := null;
    
    startpoint  integer := 0; --    0 iff no equation exists in the text
    endpoint    integer := 0;
    
    labelstart  integer := 0;
    labelend    integer := 0;
    
    v_id bigint := null;

begin  
    
    rest = ptext;
    
    loop
    
        startpoint  := position(named_formula_indicator in rest);
        
        exit when startpoint = 0; -- no equation found
        
        endpoint    := position(named_formula_ending in rest);
        
        equation := substr(rest, startpoint + length(named_formula_indicator), endpoint - length(named_formula_ending) - startpoint -2);
        
        --ltrim: in case there are some blanks between the \begin{equation} and the \label
        v_label :=  substr(ltrim(equation),1,6);
        
        if (v_label like '\\label') then -- has a label
        
            labelstart := position('{' in equation);
            labelend   := position('}' in equation);
            
            v_label := substr(equation, labelstart + 1, labelend - labelstart - 1); 
            
            equation := substr(equation, labelend + 1, endpoint - 1); --this is now the euqation itself minus the \label{...}
            
        else  --no label, create random name
        
            v_label := 'eq:____'||nextval('www.labelseq');
            
        end if;
        
        equation := REGEXP_REPLACE(equation,'\s+$', '');
        
        if (right(equation, 1) like ',') then                -- get rid of the last comma in case there is one for format
            equation := substr(equation, 1, length(equation)-1);
        end if;
        
        --raise notice 'label: %, eq: %', label, equation;
        
        select id into v_id from www.equation where label = lower(v_label);
        
        if (v_id is null) then
            insert into www.equation (label, equation, count) values (lower(v_label), equation, 1);
        else
            update www.equation set count = count +1 where id = v_id; --if the real equation differs it won't be stored
        end if;
        
        rest := substring(rest for startpoint-1) || substring(rest from (endpoint + length(named_formula_ending)));
                -- the text without the equation recursivly, until there is no euqation
   
   end loop;
   
   return rest;
   
end;
$$; 
  
insert into www.texts (name, text)
values
('nerdkack',
'At this point it is also advantageous to check how the Reference~\cite{lamport} is cited above, as well as its format (which differ from journal to journal, but this style used here is required by Physical Review). If you want to cite the course textbook, please take a look at Ref.~\cite{giordano} below. To cite a journal reference of Project 2, shown below as Ref.~\cite{whelan}, you can just copy and paste its source version, as well as to continue using the same style in the future (where you show authors by their last names and first initial, first page of the article, journal volume in bold, etc).

To make equations which have appeared in Project 1 look more elegant (or in accord with the style guides of 
Rev\TeX4, please take a look at following suggestions and tips:

\begin{itemize}

\item While symbols in math formulae usually appear in italic, some of them should remain in roman--that is we should see \textcolor{red}{$\exp(x)$} and \textcolor{red}{$\sin(x)$} instead of \textcolor{blue}{$exp(x)$} and \textcolor{blue}{$sin(x)$},

\item if you need to use a mathematical function which does not have specific command associated with it (as in the above cases of $\exp$ and $\sin$), you can always change style within math environment so that in Project 1 you get ${\rm max}(\tau_A/\tau_B,1)$ rather than $max(\tau_A/\tau_B,1)$,

\item usage of commands for fraction should be correlated with the position of the fraction within the formula---for example, if embedded into the text, it is much nicer to see $\tau_A/\tau_B$ instead of $\frac{\tau_A}{\tau_B}$; similarly, in the displayed equations it is better to have 
\begin{equation} \label{eq:exp_function}
e^{-t/\tau} \hspace {0.5in} {\rm instead \ of} \hspace{0.5in} e^{-\frac{t}{\tau}},
\end{equation}
or
\begin{equation}
\exp \left(-\frac{t}{\tau} \right) \hspace {0.5in} {\rm instead \ of} \hspace{0.5in} \exp(-\frac{t}{\tau}),
\end{equation}
which is also the style adopted in the textbook (obviously typed in some kind of \TeX! package - many publishers have their own set of macros defined on the top of plain \TeX), as you can see in Eq.~(1.2) on page 1 of Ref.~\cite{giordano}.

\item the symbols of chemical elements should be typed in roman, while its atomic or mass numbers, as well 
as its usage in chemical formulae, require subscripts or superscripts which can be typed only using the math mode in \LaTeX; one way to do this mix is demonstrated in these examples: $^{234}$U,  $^{234}$U$_{92}$, and H$_2$O,

\item similarly to the previous item, physical units should appear in roman spaced away from the number of a quantity, as shown here: $\tau_A=1$ s, $T=273$ K, and if you are interested in nanoscience might find useful that length $L=1$ nm is the same as $L=10$ \AA{}.

\item one of the complicated equations of Project 1, which was often typed as, e.g.,
\begin{equation}
\frac{\frac{1}{\tau_A}N_{B0} e^{-\frac{t}{\tau_B}+\frac{t}{\tau_B}}}{\frac{1}{\tau_A}-\frac{1}{\tau_B}},
\end{equation}
would look much more pleasing to an eye if it had appeared as
\begin{equation}
\frac{N_{B0} e^{-t/\tau_B + t/\tau_B}}{1 - \tau_A/\tau_B} \hspace{0.5in} {\rm or} \hspace{0.5in} \frac{N_{B0}}{1 - \tau_A/\tau_B}  \exp \left(-\frac{t}{\tau_B} + \frac{t}{\tau_B} \right),
\end{equation}

\item take of look of the source of Eq.~(\ref{eq:exp_function}) which contains a  label that can be 
called anywhere in the text, as demonstrated in the source of this item (the best practice is to label 
each equation when it is introduced into the text); the same method applies to Figures where we 
can reference Fig.~\ref{fig:decay} by labeling the set of commands (in the source file) which allow us to input an  EPS file into the \LaTeX document,

\vspace{0.2in}

%
\begin{figure}[ht]
\centerline{\includegraphics[scale=0.3,angle=0]{decay.eps}}
\caption{Number of radioactive nuclei as a function of time obtained from the Euler method. The time constant for the decay is $\tau=1$ s and the discretization time step is $\Delta t=0.01$ s. }\label{fig:decay}
\end{figure}
%


\item any figure containing plots of physical quantities must have clearly labeled axes, together with units in which these quantities are measured; also, figures without caption are hard to understand---many figures that we are striving to obtain through our {\bf \em computational projects} are attempts to reproduce those in the textbook or research papers, so you can get clues for possible captions (into which you can also input equations explaining the values of relevant parameters) by checking figures of particular chapter related to the project; an example of possible Figure captions for Project 1 is showing in Fig.~\ref{fig:decay},

\item here is an advanced example of typing a symmetric (${\bf A}^{\rm T}={\bf A}$) $2 \times 2$ matrix, which you will find useful for Project 3
\begin{equation} \label{eq:matrix}
{\bf A}=\left( \begin{array}{cc}
     a & b \\
    -b & c
  \end{array} \right).
\end{equation}

\item to type quantum-mechanical formulae in Project 1, you will need wave function in one-dimension $\Psi(x)=\langle x | \Psi \rangle$, wave function in three dimensions $\Psi({\bf r})=\langle {\bf r} | \Psi \rangle$ [or $\Psi(\vec{r})$], and the time-dependent Schr\"{o}dinger equation 
\begin{equation}\label{eq:schrodinger}
i \hbar \frac{\partial \Psi(x,t)}{\partial t} = \left[ -\frac{\hbar^2}{2m}  \frac{\partial^2}{\partial x^2}+V(x) \right] \Psi(x,t),
\end{equation}
where $V(x)$ is some potential in 1D, $\hbar=h/2\pi$ is the Planck constant divided by $2\pi$, and this equation also shows how to type first and higher order partial derivatives of a function');  
  
  
  
  
  
--this should extract the equations and store them to the DB :)  
  select www.extract_equations(text) from www.texts;
