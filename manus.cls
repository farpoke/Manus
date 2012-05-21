% Version 1&2: Cecilia Kjellman, cecilia.kjellman@gmail.com
% Version 2: Anton Mårtensson, anton.v.martensson@gmail.com

\NeedsTeXFormat{LaTeX2e}[1994/06/01]
\ProvidesClass{manusii}[2012/05/19]



%%%%%%%%%% Introduktion %%%%%%%%%%

% Klassen baseras på article med A4 paper.
\LoadClass[a4paper,10pt]{article}

% Använd paket för att testa om det är XeLaTeX som körs och ladda olika
% sätt att hantera unicode beroende på.
\RequirePackage{ifxetex}
\ifxetex
	\RequirePackage[T1]{fontenc}
\else
	\RequirePackage[utf8]{inputenc}
\fi

% Behöver några fler paket:
\RequirePackage{ifthen} % För booleaner och \ifthenelse.
\RequirePackage{makeidx} % För sakregister.
\RequirePackage[usenames,dvipsnames]{xcolor} % För färger.
\RequirePackage{tikz} % För indikatoreffekter. Måste vara efter xcolor.

% Lite klassalternativ...
\newcommand\simpleoption[1]{%
	\newboolean{#1}%
	\setboolean{#1}{false}%
	\DeclareOption{#1}{\setboolean{#1}{true}}%
}

% Ett klassalternativ för svartvit utskrift.
\simpleoption{svartvit}

% Ett klassalternativ för scensammanfattningar.
\simpleoption{sammanfattningar}

% Hantera okända klassalternativ.
\DeclareOption*{\typeout{! Klassen manusii känner inte igen \CurrentOption.}}

% Tolka givna alternativ.
\ProcessOptions



%%%%%%%%%% Karaktärer %%%%%%%%%%

% \nyroll[färg]{namn} : Skapa en karaktär.
\newcommand\nyroll[2][black]{%
	\ifthenelse{\boolean{svartvit}}{%
		% Svartvitt: karaktären får svart text och vit indikator.
		\@newactor{#2}{black}{white}{true}%
	}{%
		% Ej svartvitt: karaktären får matchande text och indikator.
		\@newactor{#2}{#1}{#1}{true}%
	}%
}

% \nyhjalproll[färg]{namn} : Skapa en ny "karaktär" utan indikator.
\newcommand\nyhjalproll[2][black]{%
	\ifthenelse{\boolean{svartvit}}{%
		% Svartvitt: karaktären får svart text och vit indikator.
		\@newactor{#2}{black}{white}{false}%
	}{%
		% Ej svartvitt: karaktären får matchande text och indikator.
		\@newactor{#2}{#1}{#1}{false}%
	}%
}

% Temporär låda för beräkning av namnbredd.
\newsavebox{\sl@namewdbox}

% \@newactor{namn}{textfärg}{indikatorfärg} : Skapa en ny karaktär.
\newcommand\@newactor[4]{%
	% Räkna upp antalet karaktärer.
	\stepcounter{@ctors}%
	% Skapa kommando för att skriva ut en replik från karaktären.
	\expandafter\newcommand\csname#1\endcsname[1]{%
		\sl@line{#1}{##1}{#2}{true}}%
	% Skapa kommando för att skriva ut agerande från karaktären.
	\expandafter\newcommand\csname#1gr\endcsname[1]{%
		\sl@line{\tiny#1}{\textit{##1}}{#2}{true}}%
	% Lägg till indikator.
	\ifthenelse{\equal{#4}{true}}{%
		% Skapa en ny boolean för att hålla reda på karaktärens status.
		\newboolean{#1in}%
		\setboolean{#1in}{false}%
		\newboolean{#1sub}%
		\setboolean{#1sub}{false}%
		% Lägg till indikator.
		\sl@newind{#1in}{#1sub}{#3}%
		% Skapa kommandon för att kalla in/ut karaktären.
		\expandafter\newcommand\csname#1in\endcsname{%
			\setboolean{#1in}{true}%
			\setboolean{#1sub}{false}}%
		\expandafter\newcommand\csname#1ut\endcsname{%
			\setboolean{#1in}{false}}%
		\expandafter\newcommand\csname#1sub\endcsname{%
			\setboolean{#1sub}{true}}%
		\expandafter\newcommand\csname#1subslut\endcsname{%
			\setboolean{#1sub}{false}}%
	}{}%
	% Räkna ut namnbredd.
	\savebox{\sl@namewdbox}{#1\hspace{\sl@colspace}}%
	\ifdim\wd\sl@namewdbox>\sl@maxnamewd%
		\setlength{\sl@maxnamewd}{\wd\sl@namewdbox}%
	\fi%
}



%%%%%%%%%% Sektionering %%%%%%%%%%

\renewcommand\contentsname{Innehåll}

% \akt{första-scen-nummer} : Börja en ny akt, på ny sida, eventuellt
%                            med givet nummer till första scen.
\newcommand\akt[1][1]{%
	\newpage%
	\stepcounter{akt}%
	\section*{\hspace{\sl@numwidth}\theakt}%
	\addcontentsline{toc}{section}{\theakt}%
	\setcounter{scen}{#1}%
	\addtocounter{scen}{-1}%
}

% \scen{titel}{sammanfattning} : Börja på en ny scen.
\newcommand{\scen}[2]{%
	\vspace{1em}%
	\stepcounter{scen}%
	\subsection*{\hspace{\sl@numwidth}\thescen: #1}%
	\addcontentsline{toc}{subsection}{\thescen: #1}%
	\sammanfattning{#2}%
	\vspace{1em}%
}



%%%%%%%%%% Sammanfattningar %%%%%%%%%%

\newwrite\manus@sfout
\immediate\openout\manus@sfout=\jobname.sf

\newcommand\sammanfattning[1]{%
	\ifthenelse{\boolean{sammanfattningar}}{%
		\hbox{\hspace{\sl@namewidth}\parbox{\sl@linewidth}{#1}}%
	}{}%
	\immediate\write\manus@sfout{%
		\detokenize{\paragraph}{\theakt, \thescen:} #1%
	}%
}

\newcommand\sammanfattningslista{%
	\section*{Sammanfattning}%
	\addcontentsline{toc}{section}{Sammanfattning}%
	
	\immediate\closeout\manus@sfout%
	\input{\jobname.sf}%
}



%%%%%%%%%% Kupletter %%%%%%%%%%

\ifthenelse{\boolean{svartvit}}
	{\definecolor{kuplettcolor}{rgb}{0,0,0}}
	{\definecolor{kuplettcolor}{rgb}{0.8,0.51,0}}

\newenvironment{kuplett}{%
	\newcommand{\titel}[1]{\def\ktitel{##1}}%
	\newcommand{\deltagare}[1]{\def\kdeltagare{##1}}%
	\newcommand{\beskrivning}[1]{%
		\def\kbeskrivning{##1}%
	}%
	\newcommand{\melodi}[1]{\def\kmelodi{##1}}%
	\titel{\ }%
	\deltagare{\ }%
	\beskrivning{\ }%
	\melodi{\ }%
}{%
	\subsection*{\hspace{\sl@numwidth}\Large\textcolor{kuplettcolor}{%
		Kuplett: \MakeUppercase{\ktitel}%
	}}%
	\addcontentsline{toc}{subsubsection}{%
		\textcolor{kuplettcolor}{\MakeUppercase{\ktitel}}\\%
		\kdeltagare%
	}%
	\immediate\write\manus@sfout{%
		\detokenize{\kupletttitel}{\ktitel}%
	}%
	\enkelrad{%
		Melodiförslag: \emph{\kmelodi}\\%
		\texttt{Melodi:}\\%
		Deltagare: \emph{\kdeltagare}\\%
		Beskrivning: \emph{\kbeskrivning}%
	}\vspace{1em}%
	
}

\newcommand\kuplett@sf[2]{%
}

\newcommand\kupletttitel[1]{%
	\par\vspace{1em}%
	\textcolor{kuplettcolor}{\MakeUppercase{#1}}%
}



%%%%%%%%%% Rekvisita %%%%%%%%%%

% \rekv{rekvisita} : Markera och indexera rekvisita.
\DeclareRobustCommand\rekv[1]{\fbox{#1}\index{\theakt!#1}}

% Använd makeindex för saklista.
\makeindex
\renewcommand\indexname{Sakregister}

% Definera om \printindex så att det sakregistret inkluderas i
% innehållsförteckningen.
\let\oldprintindex\printindex
\renewcommand\printindex{%
	\addcontentsline{toc}{section}{\indexname}%
	\oldprintindex%
}



%%%%%%%%%% Diverse kommandon %%%%%%%%%%

\newcommand\allgr[1]{\sl@line{* * *}{\textit{#1}}{black}{true}}
\newcommand\berattare[1]{\enkelrad[true]{%
	\tt%
	\fontdimen2\font=0.5em%
	\fontdimen3\font=0.2em%
	\fontdimen4\font=0.2em%
	\fontdimen7\font=0.1em%
	\hyphenchar\font=`\-%
	#1%
}}
\newcommand{\citat}[1]{``#1''}
\newcommand\comment[1]{}
\newcommand\enkelrad[2][false]{%
	\sl@line{}{#2}{black}{#1}%
}
\newcommand\gr[1]{\textit{#1}}
\newcommand\rentext[1]{#1}



%%%%%%%%%% Längder %%%%%%%%%%

% Ändra LaTeX:s längder för att ta bort oönskat mellanrum.
\lineskip=0pt
\lineskiplimit=0pt
\parindent=0pt
\parskip=0pt

% Vi behöver en uppsättning egna längder.
\newlength{\sl@numwidth} % Bredden på kolumnen med repliknummer.
\newlength{\sl@namewidth} % Bredden på kolumnen med karaktärsnamn.
\newlength{\sl@linewidth} % Bredden på kolumnen med replikstext.
\newlength{\sl@indoffset} % Vertikalt skift för indikatorerna.
\newlength{\sl@indwidth} % Bredd på varje indikator.
\newlength{\sl@linespace} % Extra avstånd mellan varje repliksrad.
\newlength{\sl@colspace} % Avstånd mellan kolumner.

% Sätt några defaultvärden.
\setlength{\sl@numwidth}{3em}
\setlength{\sl@namewidth}{0pt} % Denna längd räknas om senare.
\setlength{\sl@indoffset}{0pt}
\setlength{\sl@indwidth}{10pt}
\setlength{\sl@linespace}{5pt}
\setlength{\sl@colspace}{1em}

% sl@computelinewidth : Räkna ut lämplig bredd på repliksinnehåll.
\newcommand\sl@computelinewidth{%	
	\setlength{\sl@linewidth}{\textwidth}%
	%\addtolength{\sl@linewidth}{-\sl@numwidth}%
	\addtolength{\sl@linewidth}{-\sl@namewidth}%
	%\addtolength{\sl@linewidth}{-\sl@colspace}%
	%\addtolength{\sl@linewidth}{-\value{sl@indicators}\sl@indwidth}%
}

% indikatorbredd{bredd} : Ändra bredden på indikatorerna.
\newcommand\indikatorbredd[1]{%
	\setlength{\sl@indwidth}{#1}%
	\sl@computelinewidth%
}

%%%%% Hjälplängder

\newlength{\sl@contenttotal} % Storlek på repliksinnehåll.
\newlength{\sl@indheight} % Storlek på indikatorblock.

% Längsta bredd på rollnamn.
\newlength{\sl@maxnamewd}
\setlength{\sl@maxnamewd}{0pt}

% Höjd för radhöjdshjälparen (sl@linespacer).
\newlength{\sl@lsheight}
\setlength{\sl@lsheight}{\baselineskip}
\addtolength{\sl@lsheight}{6pt}



%%%%%%%%%% Räknare %%%%%%%%%%

% Räkna akter.
\newcounter{akt}
\renewcommand\theakt{Akt \arabic{akt}}

% Räkna scener.
\newcounter{scen}[akt]
\renewcommand\thescen{Scen \arabic{scen}}

% Räknare för antalet karaktärer, samt en hjälpräknare för loopar.
\newcounter{@ctors}
\newcounter{@ctoriter}
\setcounter{@ctors}{0} % Inga karaktärer än.

% Dessa räknare kommer användas innom \csname\endscname så definera
% om texten till något lämpligare
\renewcommand\the@ctors{actor@\roman{@ctors}@}
\renewcommand\the@ctoriter{actor@\roman{@ctoriter}@}

% Räknare för antalet indikatorer, samt en hjälpräknare för loopar.
\newcounter{sl@indicators}
\newcounter{sl@inditer}
\setcounter{sl@indicators}{0} % Inga indikatorer än.

% Dessa räknare kommer användas innom \csname\endscname så definera
% om texten till något lämpligare
\renewcommand\thesl@indicators{indicator@\roman{sl@indicators}@}
\renewcommand\thesl@inditer{indicator@\roman{sl@inditer}@}

% Räkna repliknummer.
\newcounter{sl@linenumber}
\setcounter{sl@linenumber}{0}



%%%%%%%%%% Indikatorer %%%%%%%%%%

% \sl@newind{ind}{sub}{färg} : Lägg till en ny indikator för de angivna
%                              booleanerna och den anvigna färgen.
\newcommand\sl@newind[3]{%
	\stepcounter{sl@indicators}%
	\expandafter\newcommand\csname\thesl@indicators ind\endcsname{%
		#1}%
	\expandafter\newcommand\csname\thesl@indicators sub\endcsname{%
		#2}%
	\expandafter\newcommand\csname\thesl@indicators color\endcsname{%
		#3}%
}

\newlength{\sl@stripetmp}
\newlength{\sl@stripeoffset}
\setlength{\sl@stripeoffset}{0pt}
\newcounter{sl@stripecount}

% \sl@indrule{färg}{overlay} : Skriv ut ett indikatorblock med den
%                              givna färgen och möjligen med overlay.
\newcommand\sl@indrule[2]{%
	\color{#1}\rule{\sl@indwidth}{\sl@indheight}%
	\ifthenelse{\boolean{#2}}{%
		\begin{tikzpicture}[overlay,x=15pt,y=15pt]
			\clip[xshift=1pt,yshift=0.1pt]
				(-\sl@indwidth,-0.2pt)
				rectangle (-2pt,\sl@indheight) ;
			\foreach \x in {0,...,\value{sl@stripecount}}
			{
				\path [draw,white,line width=5pt]
					(0,\sl@stripeoffset)
					++(0.2, \x+1) --
					++(-\sl@indwidth, -\sl@indwidth) --
					++(-0.4, -0.4)
				;
			}
		\end{tikzpicture}%
	}{}%
}

% \sl@calcstripes : Calculate number of stripes needed for overlay.
\newcommand\sl@calcstripes{%
	\setlength{\sl@stripetmp}{0pt}%
	\setcounter{sl@stripecount}{0}%
	\loop\ifdim\sl@stripetmp<\sl@indheight%
		\addtolength{\sl@stripetmp}{15pt}%
		\stepcounter{sl@stripecount}%
	\repeat%
	\stepcounter{sl@stripecount}%
	\global\addtolength{\sl@stripeoffset}{\sl@indheight}%
	\loop\ifdim\sl@stripeoffset>0pt%
		\global\addtolength{\sl@stripeoffset}{-15pt}%
	\repeat%
}

% \sl@indrules : Loopa igenom alla karaktärer och skriv ut indikatorer.
\newcommand\sl@indrules{%
	\sl@calcstripes%
	\setcounter{sl@inditer}{0}%
	\loop\ifnum\value{sl@inditer}<\value{sl@indicators}%
		\stepcounter{sl@inditer}%
		\ifthenelse{\boolean{\csname\thesl@inditer ind\endcsname}}{%
			\sl@indrule%
				{\csname\thesl@inditer color\endcsname}%
				{\csname\thesl@inditer sub\endcsname}%
		}{%
			% Skriv ut en vit indikator vid frånvaro.
			\sl@indrule{white}{false}%
		}%
	\repeat%
}



%%%%%%%%%% Replikrader %%%%%%%%%%

% sl@linespacer : Ett hjälpkommando som ser till att raderna får
%                 rätt storlek och avstånd.
\newcommand\sl@linespacer{%
	\raisebox{-3pt}[1em][3pt]{}%
}

% Temporär låda för att beräkna storleken på replikinnehållet.
\newsavebox{\sl@contentbox}

% sl@line{namn}{text} : Huvudkommandot som skriver ut en repliksrad.
\newcommand\sl@line[4]{%
	% Räkna ny rad.
	\stepcounter{sl@linenumber}%
	% Spara tillfälligt undan innehållet i en låda.
	\savebox{\sl@contentbox}{
		\parbox{\sl@linewidth}{\sl@linespacer#2\sl@linespacer}}%
	% Räkna ut längder från innehållsstorleken.
	\setlength{\sl@contenttotal}{\ht\sl@contentbox}%
	\addtolength{\sl@contenttotal}{\dp\sl@contentbox}%
	\setlength{\sl@indheight}{\sl@contenttotal}
	\addtolength{\sl@indheight}{\sl@linespace}
	% Skriv ut en rad.
	\hbox{%
		% Nummer:
		\hspace{-\sl@numwidth}%
		\vbox to \sl@contenttotal{\hbox to \sl@numwidth{%
			\hfil% För högerjustering.
			\sl@linespacer\thesl@linenumber\sl@linespacer%
			\hspace{\sl@colspace}%
		}\vfil}%
		% Namn:
		\vbox to \sl@contenttotal{\hbox to \sl@namewidth{%
			\color{#3}%
			\sl@linespacer#1\sl@linespacer%
		\hfil}\vfil}%
		% Innehåll:
		\vbox to \sl@contenttotal{\hbox to \sl@linewidth{%
				\parbox{\sl@linewidth}{%
					%\raggedright%
					\color{#3}%
					\sl@linespacer#2\sl@linespacer%
				}%
		\hfil}\vfil}%
		% Indikatorer:
		\ifthenelse{\equal{#4}{true}}{
			\raisebox{\sl@indoffset}[0pt][0pt]{%
				\hspace{\sl@colspace}%
				\sl@indrules%
				\hspace{-\value{sl@indicators}\sl@indwidth}%
				\hspace{-\sl@colspace}%
			}%
		}{}%
	}%
	\vspace{\sl@linespace}% Extra radavstånd om så önskas.
}



%%%%%%%%%% Automatiska beräkningar %%%%%%%%%%

% Öka bredden för karaktärsnamnskolumnen så långt som behövs.
% Notera att om \sl@namewidth har sats till ett större värde innan
% \begin{document} så görs ingenting.
\AtBeginDocument{%
	\ifdim\sl@maxnamewd>\sl@namewidth%
		\setlength{\sl@namewidth}{\sl@maxnamewd}%
	\fi%
}

% Räkna ut den tillåtna bredden på repliktextskolumnen.
\AtBeginDocument{\sl@computelinewidth}
