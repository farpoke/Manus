% Version 1&2: Cecilia Kjellman, cecilia.kjellman@gmail.com
% Version 2: Anton Mårtensson, anton.v.martensson@gmail.com

\NeedsTeXFormat{LaTeX2e}[1994/06/01]
\ProvidesClass{manus}[2012/05/21]



%%%%%%%%%% Introduktion %%%%%%%%%%

% Klassen baseras på article med A4 paper.
\LoadClass[a4paper,10pt,twoside]{article}

% Använd paket för att testa om det är XeLaTeX som körs och ladda olika
% sätt att hantera unicode beroende på.
\RequirePackage{ifxetex}
\ifxetex
	\RequirePackage[T1]{fontenc}
\else
	\RequirePackage[utf8]{inputenc}
\fi

% Behöver några fler paket:
\RequirePackage{array} % För rollbeskrivningar.
\RequirePackage{ifthen} % För booleaner och \ifthenelse.
\RequirePackage{makeidx} % För sakregister.
\RequirePackage{needspace} % För bättre sidbrytning.
\RequirePackage{rotating} % För rubriker till statistiktabellen.
\RequirePackage[usenames,dvipsnames]{xcolor} % För färger.
\RequirePackage{tikz} % För indikatoreffekter. Måste vara efter xcolor.

% Lite klassalternativ...
\newcommand\manus@alternativ[1]{%
	\newboolean{#1}%
	\setboolean{#1}{false}%
	\DeclareOption{#1}{\setboolean{#1}{true}}%
}

% Ett klassalternativ för svartvit utskrift.
\manus@alternativ{svartvit}

% Ett klassalternativ för scensammanfattningar.
\manus@alternativ{sammanfattningar}

% Ett klassalternativ för statistikgrafer.
\manus@alternativ{grafer}

% Hantera okända klassalternativ.
\DeclareOption*{\typeout{! Dokumnetklassen Manus känner inte igen \CurrentOption.}}

% Tolka givna alternativ.
\ProcessOptions



%%%%%%%%%% Längder %%%%%%%%%%

% Ändra LaTeX:s längder för att ta bort oönskat mellanrum.
\lineskip=0pt
\lineskiplimit=0pt
\parindent=0pt
\parskip=0pt

% Vi behöver en uppsättning egna längder.
\newlength{\manus@numbredd} % Bredden på kolumnen med repliknummer.
\newlength{\manus@namnbredd} % Bredden på kolumnen med karaktärsnamn.
\newlength{\manus@textbredd} % Bredden på kolumnen med replikstext.
\newlength{\manus@indskift} % Vertikalt skift för indikatorerna.
\newlength{\manus@indbredd} % Bredd på varje indikator.
\newlength{\manus@radavstand} % Extra avstånd mellan varje repliksrad.
\newlength{\manus@kolavstand} % Avstånd mellan kolumner.
\newlength{\manus@stat@kolbredd} % Bredden på kolumner i statistiktabellen.
\newlength{\manus@indkant} % Kantbredd för indikatorer (subspel).
\newlength{\manus@randsep} % Avstånd mellan ränder för subspelsindikation.
\newlength{\manus@randbredd} % Bredd på ränder för subspelsindikation.

% Sätt några defaultvärden.
\setlength{\manus@numbredd}{3em}
\setlength{\manus@namnbredd}{0pt} % Denna längd räknas om senare.
\setlength{\manus@indbredd}{10pt}
\setlength{\manus@radavstand}{5pt}
\setlength{\manus@kolavstand}{1em}
\setlength{\manus@stat@kolbredd}{3.5em}
\setlength{\manus@indkant}{2pt}
\setlength{\manus@randsep}{10pt}
\setlength{\manus@randbredd}{5pt}
%
\setlength{\manus@indskift}{-0.5\manus@radavstand}

%% manus@beraknabredd
% Räkna ut lämplig bredd på repliksinnehåll.
\newcommand\manus@beraknabredd{%	
	\setlength{\manus@textbredd}{\textwidth}%
	\addtolength{\manus@textbredd}{-\manus@namnbredd}%
}

%% indikatorbredd{bredd}
%
% Ändra bredden på indikatorerna.
\newcommand\indikatorbredd[1]{%
	\setlength{\manus@indbredd}{#1}%
	\manus@beraknabredd%
}

%%%%% Hjälplängder

\newlength{\manus@radstorlek} % Storlek på repliksinnehåll.
\newlength{\manus@indhojd} % Storlek på indikatorblock.

% Längsta bredd på rollnamn.
\newlength{\sl@maxnamewd}
\setlength{\sl@maxnamewd}{0pt}

% Höjd för radhöjdshjälparen (manus@radavstandr).
\newlength{\manus@radhjalphojd}
\setlength{\manus@radhjalphojd}{\baselineskip}
\addtolength{\manus@radhjalphojd}{6pt}

% Hjälplängder för subspelsindikatorer.
\newlength{\manus@randtmp}
\newlength{\manus@randskift}
\setlength{\manus@randskift}{0pt}

% Hjälplängd för statistikberäkning.
\newlength{\manus@stat@tmp}

% Statistiklängd för aktlängd.
\newlength{\manus@aktlangd}
\setlength{\manus@aktlangd}{0pt}



%%%%%%%%%% Räknare %%%%%%%%%%

% Räkna akter.
\newcounter{akt}
\renewcommand\theakt{Akt \arabic{akt}}

% Räkna scener.
\newcounter{scen}[akt]
\renewcommand\thescen{Scen \arabic{scen}}

% Räkna repliknummer.
\newcounter{manus@radnummer}
\setcounter{manus@radnummer}{0}

% Räkna antal indikatorer.
\newcounter{manus@indikatorer}
\setcounter{manus@indikatorer}{0}

% Hjälpräknare för beräkning av antal ränder för subspelsindikatorer.
\newcounter{manus@randantal}



%%%%%%%%%% Dirty Tricks á la Knuth %%%%%%%%%%

% Temporär sparning av tokenlistor.
\newtoks\tmp@toks@a
\newtoks\tmp@toks@b

%% \NewList\namn
%
% Gör \namn till en ny, tom, lista.
\def\NewList#1{\let#1\empty}

%% \Append<stuff>\To\lista
%
% Lägger <stuff> till slutet av \lista.
\def\Append#1\To#2{%
	\tmp@toks@a={\\{#1}}%
	\tmp@toks@b=\expandafter{#2}%
	\xdef#2{\the\tmp@toks@b\the\tmp@toks@a}%
}



%%%%%%%%%% Karaktärer %%%%%%%%%%

% Lite TeX-magi för att hantera valfria argument vid rollskapande.
% Ny roll skapas genom syntaxen \nyroll[färg]{namn}[utskriftsnamn]
%
\def\nyroll{\@ifnextchar[\nyroll@ii\nyroll@i}
\def\nyroll@i#1{\nyroll@ii[black]{#1}}% Defaultfärg är svart.
\def\nyroll@ii[#1]#2{%
	\@ifnextchar[%
		{\nyroll@iii[#1]{#2}}%
		{\nyroll@iii[#1]{#2}[#2]}% Defaultutskriftsnamn är kommandonamnet.
}
\def\nyroll@iii[#1]#2[#3]{\@nyroll{#1}{#2}{#3}}% Komplett anrop.

%% \@nyroll{färg}{kommandonamn}{utskriftsnamn}
%
% Skapa en karaktär. Kommandon, räknare etc. får namn utefter kommandonamnet
% men det som skrivs ut är utskriftsnamnet.
\newcommand\@nyroll[3]{%
	\ifthenelse{\boolean{svartvit}}{%
		% Svartvitt: karaktären får svart text och vit indikator.
		\manus@nyroll{#2}{#3}{black}{white}{true}%
	}{%
		% Ej svartvitt: karaktären får matchande text och indikator.
		\manus@nyroll{#2}{#3}{#1}{#1}{true}%
	}%
}

% Lite TeX-magi för att hantera valfria argument vid hjälprollskapande.
% Ny hjälproll skapas genom syntaxen \nyhjalproll[färg]{namn}[utskriftsnamn]
%
\def\nyhjalproll{\@ifnextchar[\nyhjalproll@ii\nyhjalproll@i}
\def\nyhjalproll@i#1{\nyhjalproll@ii[black]{#1}}% Defaultfärg är svart.
\def\nyhjalproll@ii[#1]#2{%
	\@ifnextchar[%
		{\nyhjalproll@iii[#1]{#2}}%
		{\nyhjalproll@iii[#1]{#2}[#2]}% Defaultutskriftsnamn är kommandonamnet.
}
\def\nyhjalproll@iii[#1]#2[#3]{\@nyhjalproll{#1}{#2}{#3}}% Komplett anrop.

%% \nyhjalproll{färg}{namn}{utskriftsnamn}
%
% Skapa en ny "karaktär", utan indikator. Se \@nyroll.
\newcommand\@nyhjalproll[3]{%
	\ifthenelse{\boolean{svartvit}}{%
		% Svartvitt: karaktären får svart text och vit indikator.
		\manus@nyroll{#2}{#3}{black}{white}{false}%
	}{%
		% Ej svartvitt: karaktären får matchande text och indikator.
		\manus@nyroll{#2}{#3}{#1}{#1}{false}%
	}%
}

% Temporär låda för beräkning av namnbredd.
\newsavebox{\manus@namn@tmpbox}

%% \manus@nyroll{kommandonamn}{utskriftsnamn}{textfärg}{indikatorfärg}{indikator?}
%
% Skapa, faktiskt, en ny karaktär. Om parameter #4 är true skapas även en
% indikator med den givna färgen, annars inte.
\newcommand\manus@nyroll[5]{%
	% Spara utskriftsnamn på lägligt ställe. Detta utnyttjas för att kunna ändra
	% utskriftsnamnet på en karaktär mitt i manus. Statistiken håller sig till
	% orginalnamn.
	\expandafter\gdef\csname#1@namn\endcsname{#2}%
	% Skapa kommando för att skriva ut en replik från karaktären.
	\expandafter\newcommand\csname#1\endcsname[1]{%
		\manus@skrivrad{\csname#1@namn\endcsname}{\bfseries{##1}}{#3}{true}%
		% Räkna raden till statistiken.
		\ifthenelse{\equal{#5}{true}}{%
			\stepcounter{#1@stat@repliker}%
			\addtolength{\csname#1@stat@repliker\endcsname}{\manus@indhojd}%
		}{}%
		\manus@raknastats%
	}%
	% Skapa kommando för att skriva ut agerande från karaktären.
	\expandafter\newcommand\csname#1gr\endcsname[1]{%
		\manus@skrivrad{\tiny\csname#1@namn\endcsname}%
			{\bfseries{\textit{##1}}}{#3}{true}%
		% Räkna raden till statistiken.
		\ifthenelse{\equal{#5}{true}}{\stepcounter{#1@stat@agerande}}{}%
		\manus@raknastats%
	}%
	% Lägg till indikator.
	\ifthenelse{\equal{#5}{true}}{%
		% Skapa en ny boolean för att hålla reda på karaktärens status.
		\newboolean{#1@in}%
		\setboolean{#1@in}{false}%
		\newboolean{#1@sub}%
		\setboolean{#1@sub}{false}%
		% Lägg till indikator.
		\manus@nyind{#1@in}{#1@sub}{#4}%
		% Lägg till statistik.
		\manus@nystat{#1}{#2}{#1@in}{#1@sub}{#3}%
		% Skapa kommandon för att kalla in/ut karaktären.
		\expandafter\newcommand\csname#1in\endcsname{%
			\setboolean{#1@in}{true}%
			\setboolean{#1@sub}{false}%
			\@ifstar{}{%
			\csname#1gr\endcsname{\csname#1@namn\endcsname\ kommer in på scen.}}}%
		\expandafter\newcommand\csname#1ut\endcsname{%
			\setboolean{#1@in}{false}%
			\@ifstar{}{%
			\csname#1gr\endcsname{\csname#1@namn\endcsname\ går av scen.}}}%
		\expandafter\newcommand\csname#1sub\endcsname{%
			\setboolean{#1@sub}{true}}%
		\expandafter\newcommand\csname#1subslut\endcsname{%
			\setboolean{#1@sub}{false}}%
	}{}%
	% Räkna ut största namnbredd.
	\savebox{\manus@namn@tmpbox}{#2\hspace{\manus@kolavstand}}%
	\ifdim\wd\manus@namn@tmpbox>\sl@maxnamewd%
		\setlength{\sl@maxnamewd}{\wd\manus@namn@tmpbox}%
	\fi%
}

%% \namnbyte{kommandonamn}{utskriftsnamn}
%
% Ändra utskriftsnamnet för karaktären med det angivna kommandonamnet till det
% angivna, nya, utskriftsnamnet.
\newcommand\namnbyte[2]{%
	\expandafter\gdef\csname#1@namn\endcsname{#2}%
}



%%%%%%%%%% Karaktärsbeskrivningsmiljö 
%
%% \begin{rollbeskrivning}
%
% En miljö för att beskriva karaktärer.
%
%% \namn{Namn}             : Ange namnet för rollen.
%% \bild{bild}     : Bild på karaktären.
%% \beskrivning{beskrivning} : Ange beskrivning för denna karaktär.
%% \ner{Förflyttning nedåt}           :Ange förflyttning nedåt
%% \hoger{Förflyttning höger}		: Ange förflyttning i sidled
%
%% \end{rollbeskrivning}
%
\newsavebox{\bildbox}%
\newcounter{skrivnaRollBeskrivningar}%
%
\newlength{\rollbildhojd}
\setlength{\rollbildhojd}{0.5\textheight}
\newlength{\rollbeskrivningsflytt}
\setlength{\rollbeskrivningsflytt}{-0.5\textheight}
\newlength{\beskrivningsbredd}
%
%
\newenvironment{rollbeskrivning}{%
	% Deklarera kommandon för rollbeskrivning.
	\newcommand{\namn}[1]{\def\knamn{##1}}%
	\newcommand{\bild}[1]{\def\kbild{##1}}%
	\newcommand{\beskrivning}[1]{\def\kbeskrivning{##1}}%
	\newcommand{\ner}[1]{\def\kner{##1}}%
	\newcommand{\hoger}[1]{\def\khoger{##1}}%
	% Sätt alla värden till tomrum.
	\namn{\ }%
	\bild{placeholder}%
	\beskrivning{\ }%
	\ner{0px}%
	\hoger{opx}%
	

}{%
	%Skriv ut rubrik om första karaktären
	\ifthenelse{\theskrivnaRollBeskrivningar=0}{%
		\section*{\Huge Spexkaraktärer}%
		\addcontentsline{toc}{section}{Karaktärsbeskrivningar}%
	}{}%
	\stepcounter{skrivnaRollBeskrivningar}%
%
	\savebox{\bildbox}{\includegraphics[height=\rollbildhojd]{\kbild}}%
	\setlength{\beskrivningsbredd}{\textwidth}%
	\addtolength{\beskrivningsbredd}{-\wd\bildbox}%
	%\the
	%Vilket håll skall det ligga åt?
	\ifthenelse{\isodd{\theskrivnaRollBeskrivningar}}{%
			%\vspace{\kner}\hspace{\khoger}%
			\begin{tabular}{m{\beskrivningsbredd} c}%
				\vspace{\rollbeskrivningsflytt}\begin{tabular}{m{\beskrivningsbredd}}%
					{\large\textbf\knamn}\\%
					\kbeskrivning%
				\end{tabular}&%
				%\fbox{\vbox to \ht\bildbox{\hbox to \wd\bildbox{%
				\includegraphics[height=\rollbildhojd]{\kbild}%\\
				%\hfil}\vfil}}%
			\end{tabular}%
	}{%
			%\vspace{\kner}\hspace{\khoger}%
			%\vspace{-0.15\textheight}
			\begin{tabular}{c m{\beskrivningsbredd}}%
				\includegraphics[height=\rollbildhojd]{\kbild}&%
				\vspace{\rollbeskrivningsflytt}\begin{tabular}{m{\beskrivningsbredd}}%
					{\large\textbf\knamn}\\%
					\kbeskrivning%
				\end{tabular}%\\
			\end{tabular}%
	}%
}%



%%%%%%%%%% Sektionering %%%%%%%%%%

% Svenska, tack.
\renewcommand\contentsname{Innehåll}

%% \akt[första-scen-nummer]
%
% Börja en ny akt, på ny sida, eventuellt med givet nummer till första scen.
\newcommand\akt[1][1]{%
	% Räkna aktstatistik för den avslutade akten.
	\manus@aktstatistik%
	\setlength{\manus@aktlangd}{0pt}%
	% Påbörja den nya akten.
	\newpage%
	\stepcounter{akt}%
	\section*{\hspace{\manus@numbredd}\theakt}%
	\addcontentsline{toc}{section}{\theakt}%
	% Sätt scenräknaren så att den första scenen får önskat värde.
	\setcounter{scen}{#1}%
	\addtocounter{scen}{-1}%
}

%% \scen{titel}{sammanfattning}
%
% Börja på en ny scen.
\newcommand{\scen}[2]{%
	\vspace{1em}%
	\needspace{10\baselineskip}%
	\stepcounter{scen}%
	\subsection*{\hspace{\manus@numbredd}\thescen: #1}%
	\addcontentsline{toc}{subsection}{\thescen: #1}%
	\scensammanfattning{#2}%
	\vspace{1em}%
}



%%%%%%%%%% Sammanfattningar %%%%%%%%%%

%% \scensammanfattning{sammanfattning}
%
% Deklarera en scensammanfattning. Om "sammanfattningar" gavs som
% klassalternativ skrivs det ut vid anrop, annars inte. I båda fallen läggs
% det till i sammanfattningslistan.
\newcommand\scensammanfattning[1]{%
	% Skriv ut sammanfattningen direkt i texten om så angets.
	\ifthenelse{\boolean{sammanfattningar}}{%
		\hbox{\hspace{\manus@namnbredd}\parbox{\manus@textbredd}{#1}}%
	}{}%
	% Lägg till sammanfattningen i sammanfattningslistan.
	\manus@sfnyscen{#1}%
}

% Skapa en ny lista för sammanfattningsinformation.
\NewList\manus@sammanfattningar

%% \manus@sfnyscen{sammanfattning}
%
% Lägg till en scensammanfattning i sammanfattningslistan.
\newcommand\manus@sfnyscen[1]{%
	% Spara sammanfattning av typ "scen".
	\Append\scen\To\manus@sammanfattningar%
	\edef\tmp{\theakt, \thescen:}% Expandera akt- och scennummer.
	\expandafter\Append\tmp\To\manus@sammanfattningar%
	\Append#1\To\manus@sammanfattningar%
}

%% \manus@sfnykuplett{namn}{beskrivning}
%
% Lägg till en kuplettsammanfattning i sammanfattningslistan.
\newcommand\manus@sfnykuplett[3]{%
	% Spara sammanfattning av typ "kuplett"
	\Append\kuplett\To\manus@sammanfattningar%
	\expandafter\Append#1\To\manus@sammanfattningar%
	\expandafter\Append#2\To\manus@sammanfattningar%
	\expandafter\Append#3\To\manus@sammanfattningar%
}

%% \sammanfattningslista
%
% Skriver ut sammanfattningslistan.
\newcommand\sammanfattningslista{%
	% Ny sektion på ny sida för sammanfattningarna.
	\newpage%
	\section*{Sammanfattning}%
	\addcontentsline{toc}{section}{Sammanfattning}%
	% Skiv ut alla sammanfattningar.
	\begingroup%
	\let\newline\\%
	\def\\##1{##1}%
	\def\scen\\##1\\##2{%
		\paragraph{##1} ##2%
	}%
	\def\kuplett\\##1\\##2\\##3{%
			\par\vspace{1em}%
			\textcolor{kuplettfarg}{\MakeUppercase{##1}}\newline%
			\emph{##3}\newline%
			##2%
	}%
	\manus@sammanfattningar%
	\endgroup%
}



%%%%%%%%%% Kupletter %%%%%%%%%%

% Bestäm färgen på kupletter beroende på om klassalternativet "svartvit"
% har angetts eller inte.
\ifthenelse{\boolean{svartvit}}
	{\definecolor{kuplettfarg}{rgb}{0,0,0}}
	{\definecolor{kuplettfarg}{rgb}{0.8,0.51,0}}

%% \begin{kuplett}
%
% En kuplettmiljö.
%
%% \titel{titel}             : Ange titeln på denna kuplett.
%% \beskrivning{beskrivning} : Ange beskrivning för denna kuplett.
%% \melodi{melodi}           : Ange melodiförslag för denna kuplett.
%
%% \end{kuplett}
\newenvironment{kuplett}[1][]{%
	#1%
	% Deklarera kommandon för kuplettinformation.
	\newcommand{\titel}[1]{\def\ktitel{##1}}%
	\newcommand{\@deltagare}[1]{\xdef\kdeltagare{##1}}%
	\newcommand{\beskrivning}[1]{%
		\def\kbeskrivning{##1}%
	}%
	\newcommand{\melodi}[1]{\def\kmelodi{##1}}%
	% Sätt alla värden till tomrum.
	\titel{}%
	\@deltagare{}%
	\beskrivning{}%
	\melodi{}%
	% Om deltagare inte specificeras antags alla som är på scen delta.
	\begingroup%
	\def\\##1\\##2\\##3\\##4\\##5{% \\{namn}\\{utskriftnamn}\\{ind}\\{sub}\\{färg}
		\ifthenelse{\boolean{##3}}{%
			\ifx\kdeltagare\empty%
				\@deltagare{##2}%
			\else%
				\@deltagare{\kdeltagare, ##2}%
			\fi%
		}{}%
	}%
	\manus@statistik%
	\endgroup%
}{%
	% Skriv ut kupletten.
	\mellanrum{2em}%
	\enkelrad[true]{\vbox{%
		\hbox to \manus@textbredd{%
			\parbox{\manus@textbredd}{\textbf{\textcolor{kuplettfarg}{%
				\Large Kuplett: \MakeUppercase{\ktitel}%
			}}}%
		}%
		\vspace{5pt}%
		\hbox to \manus@textbredd{\parbox{\manus@textbredd}{%
			Melodiförslag: \emph{\kmelodi}%
		}}%
		\hbox to \manus@textbredd{\parbox{\manus@textbredd}{%
			\texttt{Melodi:}%
		}}%
		\hbox to \manus@textbredd{\parbox{\manus@textbredd}{%
			Deltagare: \emph{\kdeltagare}%
		}}%
		\hbox to \manus@textbredd{\parbox{\manus@textbredd}{%
			Beskrivning: \emph{\kbeskrivning}
		}}%
	}}%
	\mellanrum{2em}%
	% Lägg till kupletten i innehållsförteckningen
	\addcontentsline{toc}{subsubsection}{%
		\textcolor{kuplettfarg}{\MakeUppercase{\ktitel}}\\%
		Deltagare: \emph{\kdeltagare}%
	}%
	% Lägg till kuplettbeskrivning i sammanfattningslistan.
	\manus@sfnykuplett{\ktitel}{\kbeskrivning}{\kdeltagare}%
	% Räkna kuplettstatistik.
	\manus@raknakuplett%
}

%% \kuplettlista
%
% Kuplettlistan skriver ut en lista med kupletter. Egentligen bara en
% variant av sammanfattningslistan.
\newcommand\kuplettlista{%
	% Ny sektion på ny sida för listan.
	\newpage%
	\section*{Kupletter}%
	\addcontentsline{toc}{section}{Kupletter}%
	% Skiv ut alla kupletter.
	\begingroup%
	\let\newline\\%
	\def\\##1{##1}%
	\def\scen\\##1\\##2{}%
	\def\kuplett\\##1\\##2\\##3{%
			\par\vspace{1em}%
			\textcolor{kuplettfarg}{\MakeUppercase{##1}}\newline%
			\emph{##3}\newline%
			##2%
	}%
	\manus@sammanfattningar%
	\endgroup%
}



%%%%%%%%%% Rekvisita %%%%%%%%%%

%% \rekv{rekvisita}
%
% Markera och indexera rekvisita.
\newcommand\rekv[1]{%
	\fbox{#1}%
	\manus@indexrekv{#1}%
}

%% \manus@indexrekv{rekvisita}
%
% Indexera rekvisita
\newcommand\manus@indexrekv[1]{%
	\index{%
		\vspace{10pt}\textbf{\theakt}!%
		\themanus@radnummer @%
		#1: \themanus@radnummer|textit}%
}

% Använd makeindex för saklista.
\makeindex
\renewcommand\indexname{%
	Sakregister\\% Svenska, tack.
	{\normalsize Sorterad i ordningen de uppträder}\\%
	{\normalfont\normalsize Rekvista: repliknummer, \textit{sidnummer}}}%
% Förklaring av sortering

%% \rekvisitalista
%
% Skriv ut en fin rekvisitalista.
\newcommand\rekvisitalista{%
	\newpage%
	\addcontentsline{toc}{section}{Sakregister}%
	\begingroup%
	\def\thispagestyle##1{}% Tillåt inte \printindex att ändra sidlayouten.
	\printindex%
	\endgroup%
}



%%%%%%%%%% Diverse kommandon %%%%%%%%%%

\newcommand\allgr[1]{%
	\manus@skrivrad{* * *}{\bfseries{\textit{#1}}}{black}{true}%
	\manus@raknastats%
}
\newcommand\berattare[1]{\enkelrad[true]{%
	\tt%
	\fontdimen2\font=0.5em%
	\fontdimen3\font=0.2em%
	\fontdimen4\font=0.2em%
	\fontdimen7\font=0.1em%
	\hyphenchar\font=`\-%
	\begingroup%
	\renewcommand\rekv[1]{%
		\fbox{##1}%
		\manus@indexrekv{##1 (B)}%
	}%
	#1%
	\endgroup%
}}
\newcommand{\citat}[1]{``#1''}
\newcommand\comment[1]{}
\newcommand\enkelrad[2][false]{%
	\manus@skrivrad{}{#2}{black}{#1}%
}
\newcommand\gr[1]{[\textit{#1}]}
\newcommand\rentext[1]{#1}
\newcommand\mellanrum[1]{%
	\setlength{\manus@radstorlek}{#1}%
	\setlength{\manus@indhojd}{\manus@radstorlek}%
	\addtolength{\manus@indhojd}{\manus@radavstand}%
	% Skriv ut en rad.
	\hbox{%
		% Namn:
		\vbox to \manus@radstorlek{\hbox to \manus@namnbredd{%
		\hfil}\vfil}%
		% Innehåll:
		\vbox to \manus@radstorlek{\hbox to \manus@textbredd{%
		\hfil}\vfil}%
		% Indikatorer:
		\raisebox{\manus@indskift}[0pt][0pt]{%
			\hspace{\manus@kolavstand}%
			\manus@ritainds%
		}%
	}%
	\vspace{\manus@radavstand}% Extra radavstånd.
	\addtolength{\manus@aktlangd}{\manus@indhojd}% Lägg till höjden till aktlängden.
}



%%%%%%%%%% Indikatorer %%%%%%%%%%

% Skapa en ny lista med indikatorinformation.
\NewList\manus@indikatorer

%% \manus@nyind{ind}{sub}{färg}
%
% Lägg till en ny indikator för de angivna booleanerna och den anvigna
% färgen. ind skall vara namnet på den boolean som styr närvaro, sub skall
% vara namnet på den boolean som styr subspelsindikatorn.
\newcommand\manus@nyind[3]{%
	% Spara parametrarna i indikatorlistan.
	\Append#1\To\manus@indikatorer%
	\Append#2\To\manus@indikatorer%
	\Append#3\To\manus@indikatorer%
	% Räkna indikatorer för statistik.
	\stepcounter{manus@indikatorer}%
}

%% \manus@ritaind{färg}{overlay}
%
% Skriv ut ett indikatorblock med den givna färgen och med overlay om
% booleanen overlay är sann.
\newcommand\manus@ritaind[2]{%
	\color{#1}\rule{\manus@indbredd}{\manus@indhojd}%
	\ifthenelse{\boolean{#2}}{%
		\begin{tikzpicture}[overlay,x=\manus@randsep,y=\manus@randsep]
			\clip[xshift=\manus@indkant,yshift=0.1pt]
				(-\manus@indbredd,-0.2pt)
				rectangle (-2\manus@indkant,\manus@indhojd) ;
			\foreach \i in {0,...,\value{manus@randantal}}
			{
				\path [draw,white,line width=\manus@randbredd]
					(0,\manus@randskift)
					++(0.2, \i+1) --
					++(-\manus@indbredd, -\manus@indbredd) --
					++(-0.4, -0.4)
				;
			}
		\end{tikzpicture}%
	}{}%
}

%% \manus@raknarander
%
% Räkna ut antalet rander som behövs för indikatorer givet nuvarande
% storlekar och räkna ut nytt värde på randskiftet.
\newcommand\manus@raknarander{%
	% Nollställ räknare.
	\setlength{\manus@randtmp}{0pt}%
	\setcounter{manus@randantal}{0}%
	% Lägg till ränder tills vi "täcker" en tänkt indikator.
	\loop\ifdim\manus@randtmp<\manus@indhojd%
		\advance \manus@randtmp by \manus@randbredd%
		\stepcounter{manus@randantal}%
	\repeat%
	\stepcounter{manus@randantal}% Lägg till en extra för marginal.
	% Lägg till indikatorhöjden till skiftlängden.
	\global\advance \manus@randskift by \manus@indhojd%
	% Räkna ner skiftet tills vi är under eller lika med noll igen.
	\loop\ifdim\manus@randskift>0pt%
		\global\advance \manus@randskift by -\manus@randsep%
	\repeat%
}

%% \manus@ritainds
%
% Loopa igenom alla indikatorer och rita ut dem.
\newcommand\manus@ritainds{%
	% Räkna först ut värden för eventuella ränder.
	\manus@raknarander%
	% Rita ut indikatorer.
	\begingroup%
	\def\\##1\\##2\\##3{%
		\ifthenelse{\boolean{##1}}%
			{\manus@ritaind{##3}{##2}}% På scen.
			{\manus@ritaind{white}{false}}% Av scen.
	}%
	\manus@indikatorer%
	\endgroup%
}



%%%%%%%%%% Statistik %%%%%%%%%%

% Skapa en ny lista för statistikinformation.
\NewList\manus@statistik

%% \manus@nystat{namn}{utskriftsnamn}{ind}{sub}{färg}
%
% Skapa nya räknare och längder från det givna basnamnet för att räkna
% statistik. I statistiktabellen skrivs namnet ut med den angivna färgen.
\newcommand\manus@nystat[5]{%
	% Spara parametrar för statistiken.
	\Append#1\To\manus@statistik%
	\Append#2\To\manus@statistik%
	\Append#3\To\manus@statistik%
	\Append#4\To\manus@statistik%
	\Append#5\To\manus@statistik%
	% Skapa räknare för statistik.
	\newcounter{#1@stat@repliker}%
	\newcounter{#1@stat@agerande}%
	\newcounter{#1@stat@kupletter}%
	\newcounter{#1@stat@narvaro}%
	\newcounter{#1@stat@subspel}%
	% Skapa längder för statistik.
	\expandafter\newdimen\csname#1@stat@repliker\endcsname%
	\expandafter\newdimen\csname#1@stat@kupletter\endcsname%
	\expandafter\newdimen\csname#1@stat@narvaro\endcsname%
	\expandafter\newdimen\csname#1@stat@subspel\endcsname%
}

%% \manus@raknastats
%
% Räkna statistik.
\newcommand\manus@raknastats{%
	\begingroup%
	\def\\##1\\##2\\##3\\##4\\##5{%
		\ifthenelse{\boolean{##3}}{%
			\ifthenelse{\boolean{##4}}{%
				\stepcounter{##1@stat@subspel}%
				\global\advance%
					\csname##1@stat@subspel\endcsname%
					by \manus@indhojd%
			}{%
				\stepcounter{##1@stat@narvaro}%
				\global\advance%
					\csname##1@stat@narvaro\endcsname%
					by \manus@indhojd%
			}%
		}{}%
	}%
	\manus@statistik%
	\endgroup%
}

%% \manus@raknakuplett
%
% Räkna kuplettstatistik.
\newcommand\manus@raknakuplett{%
	\begingroup%
	\newcount\tmp@count%
	\tmp@count=0
	\def\\##1\\##2\\##3\\##4\\##5{% \\{k.namn}\\{u.namn}\\{ind}\\{sub}\\{färg}
		\ifthenelse{\boolean{##3}}{%
			\stepcounter{##1@stat@kupletter}%
			\tmp@count=\numexpr\tmp@count+1%
		}{}%
	}%
	\manus@statistik%
	\pgfmathparse{1/\tmp@count}%
	\def\\##1\\##2\\##3\\##4\\##5{% \\{k.namn}\\{u.namn}\\{ind}\\{sub}\\{färg}
		\ifthenelse{\boolean{##3}}{%
			\global\advance%
				\csname##1@stat@kupletter\endcsname%
				by \pgfmathresult pt%
		}{}%
	}%
	\manus@statistik%
	\endgroup%
}

% Skapa en ny lista med lite aktstatistik.
\NewList\manus@akter

%% \manus@aktstatistik
%
% Lägg till nuvarande akten i aktstatistiken om aktens längd är positiv.
\newcommand\manus@aktstatistik{\ifdim\manus@aktlangd>0pt%
	\edef\tmp{\theakt}
	\expandafter\Append\tmp\To\manus@akter%
	\edef\tmp{\the\manus@aktlangd}%
	\expandafter\Append\tmp\To\manus@akter%
\fi}

%% \langd@cm{längd}
%
% Längden i cm, utan enhet.
\newcommand\langd@cm[1]{%
	\setlength{\manus@stat@tmp}{\csname#1\endcsname}%
	\pgfmathtruncatemacro\stat@cm{round(0.0351459804*\manus@stat@tmp)}%
	\stat@cm%
}

%% \statistiktabell
%
% Skriv ut en tabell med statistik för roller.
\newcommand\statistiktabell{%
	% Räkna statistik för sista akten.
	\manus@aktstatistik%
	% Påbörja statistiksektion på ny sida.
	\newpage%
	\section*{Statistik}%
	\addcontentsline{toc}{section}{Statistik}%
	\vbox%
	\bgroup%
	\newcommand\kol@titel[2]{\hbox to \manus@stat@kolbredd{\hfil%
		\begin{rotate}{30}%
			##1%
			\ifx&##2&\else\ (##2)\fi%
		\end{rotate}%
	\hfil}}%
	\newcommand\stat@kol[2]%
		{\vbox to 2.5\baselineskip{%
			\hbox to \manus@stat@kolbredd{\hfil##1\hfil}%
			\hbox to \manus@stat@kolbredd{\hfil%
				\ifx&##2&--\else(##2)\fi%
			\hfil}%
			\vfil%
		}}%
	\renewcommand\vline{%
		\hspace{5pt}%
		\raisebox{0.25\baselineskip}[0pt][0pt]{\rule{1pt}{2.5\baselineskip}}%
		\hspace{5pt}%
	}%
	% Skriv ut titelrad.
	\vspace{3em}%
	\hbox{\bf%
		\hspace{1.2\manus@namnbredd}%
		\hspace{10pt}%
		\kol@titel{Repliker}{$\approx$cm}%
		\kol@titel{Agerande}{}%
		\kol@titel{Total}{}%
		\hspace{10pt}%
		\kol@titel{Kupletter}{balanserat}%
		\hspace{10pt}%
		\kol@titel{Närvaro}{$\approx$cm}%
		\kol@titel{Subspel}{$\approx$cm}%
		\kol@titel{Total}{$\approx$cm}%
	}%
	\vspace{\baselineskip}%
	% Skriv ut statistikrader.
	\def\\##1\\##2\\##3\\##4\\##5{% \\{k.namn}\\{u.namn}\\{ind}\\{sub}\\{färg}
		\hbox{%
			\vbox to 2.5\baselineskip{%
				\vfil%
				\hbox to 1.2\manus@namnbredd{%
					\textbf{\textcolor{##5}{##2}}%
					\hfil%
				}%
				\vfil%
				\vspace{0.5\baselineskip}%
			}%
			\vline%
			\stat@kol%
				{\number\value{##1@stat@repliker}}%
				{\langd@cm{##1@stat@repliker}}%
			\stat@kol%
				{\number\value{##1@stat@agerande}}%
				{}%
			\stat@kol
				{\number\numexpr%
					\value{##1@stat@repliker}+%
					\value{##1@stat@agerande}}%
				{}%
			\vline%
			\stat@kol%
				{\number\value{##1@stat@kupletter}}%
				{\pgfmathprintnumber[precision=2]%
					{\strip@pt\csname##1@stat@kupletter\endcsname}}%
			\vline%
			\stat@kol%
				{\number\value{##1@stat@narvaro}}%
				{\langd@cm{##1@stat@narvaro}}%
			\stat@kol%
				{\number\value{##1@stat@subspel}}%
				{\langd@cm{##1@stat@subspel}}%
			\stat@kol%
				{\number\numexpr%
					\value{##1@stat@narvaro}+%
					\value{##1@stat@subspel}}%
				{\setlength%
					{\manus@stat@tmp}%
					{\csname##1@stat@narvaro\endcsname}%
				\addtolength%
					{\manus@stat@tmp}%
					{\csname##1@stat@subspel\endcsname}%
				\pgfmathtruncatemacro\stat@cm%
					{round(0.0351459804*\manus@stat@tmp)}%
				\stat@cm}%
		}%
	}%
	\manus@statistik%
	\egroup% Slut på statistiktabell
	% Lägg till lite aktstatistik.
	\vspace{3em}%
	\begingroup%
	% Räkna ut totallängden.
	\newdimen\tmp@langd%
	\def\\##1\\##2{\addtolength{\tmp@langd}{##2}}%
	\manus@akter%
	% Räkna ut en skalfaktor för att passa akterna horizontellt.
	\pgfmathparse{(\textwidth-2*(\fboxrule+\fboxsep)*\value{akt})/\tmp@langd}%
	% Rita ut lådor med information, med storlek motsvarande akternas längd.
	\def\\##1\\##2{%
		\tmp@langd=##2%
		\tmp@langd=\pgfmathresult\tmp@langd%
		\pgfmathtruncatemacro\stat@cm{round(0.0351459804*##2)}%
		\fbox{\parbox{\tmp@langd}{%
			\textbf{##1}\\%
			\stat@cm\ cm%%
		}}%
	}%
	\manus@akter%
	\endgroup%
	% Lägg till statistikgrafer om klassalternativet är satt.
	\ifthenelse{\boolean{grafer}}{\newpage\manus@grafer}{}%
}



%%%%%%%%%% Grafer %%%%%%%%%%

\newcommand\manus@graf@repliker[1]{\value{#1@stat@repliker}}
\newcommand\manus@graf@total[1]{%
	\numexpr\value{#1@stat@repliker}+\value{#1@stat@agerande}\relax}
\newcommand\manus@graf@kupletter[1]{\value{#1@stat@kupletter}}

\newcommand\manus@graf@repliker@l[1]{\csname#1@stat@repliker\endcsname}
\newcommand\manus@graf@kupletter@l[1]{\csname#1@stat@kupletter\endcsname}
\newcommand\manus@graf@narvaro@l[1]{\csname#1@stat@narvaro\endcsname}
\newcommand\manus@graf@subspel@l[1]{\csname#1@stat@subspel\endcsname}
\newcommand\manus@graf@total@l[1]{%
	\dimexpr\csname#1@stat@narvaro\endcsname+\csname#1@stat@subspel\endcsname\relax}

\newcommand\manus@graf@num[2]{
	\begingroup%
	\let\graf@stats\empty%
	\def\\##1\\##2\\##3\\##4\\##5{% \\{namn}\\{utskriftnamn}\\{ind}\\{sub}\\{färg}
		\tmp@toks@a=\expandafter{\graf@stats}%
		\tmp@toks@b={\\{##2}\\{#2{##1}}\\{##5}}%
		\edef\graf@stats{\the\tmp@toks@a\the\tmp@toks@b}%
	}%
	\manus@statistik%
	\newcount\c@tmp@total%
	\newcount\c@tmp@count%
	\def\\##1\\##2\\##3{\addtocounter{tmp@total}{##2}}%
	\graf@stats%
	\def\\##1\\##2\\##3{
		\pgfmathparse{\value{tmp@count}/\value{tmp@total}*360}
		\let\angle@a=\pgfmathresult
		\addtocounter{tmp@count}{##2}
		\pgfmathparse{\value{tmp@count}/\value{tmp@total}*360}
		\let\angle@b=\pgfmathresult
		\ifthenelse{\equal{\angle@a}{\angle@b}}{}{
			\pgfmathparse{(\angle@a+\angle@b)/2}
			\let\angle@c=\pgfmathresult
			\draw[fill=##3]
				(0,0) --
				(\angle@a:1) arc (\angle@a:\angle@b:1)
				-- cycle;
			\node
				[label=\angle@c:##1,inner sep=0pt,outer sep=0pt]
				at (\angle@c:1) {};
		}
	}%
	\fbox{\vbox{%
		\hbox{\bf#1}\vspace{5pt}%
		\hbox{\begin{tikzpicture}\graf@stats\end{tikzpicture}}%
	}}%
	\endgroup%
}

\newcommand\manus@graf@dim[2]{
	\begingroup%
	\let\graf@stats\empty%
	\def\\##1\\##2\\##3\\##4\\##5{% \\{namn}\\{utskriftnamn}\\{ind}\\{sub}\\{färg}
		\tmp@toks@a=\expandafter{\graf@stats}%
		\tmp@toks@b={\\{##2}\\{#2{##1}}\\{##5}}%
		\edef\graf@stats{\the\tmp@toks@a\the\tmp@toks@b}%
	}%
	\manus@statistik%
	\newdimen\l@tmp
	\newdimen\l@tmp@total%
	\newdimen\l@tmp@count%
	\def\\##1\\##2\\##3{%
		\l@tmp=##2%
		\addtolength{\l@tmp@total}{0.001\l@tmp}%
	}%
	\graf@stats%
	\def\\##1\\##2\\##3{
		\pgfmathparse{\l@tmp@count/\l@tmp@total*360}
		\let\angle@a=\pgfmathresult
		\l@tmp=##2
		\addtolength{\l@tmp@count}{0.001\l@tmp}
		\pgfmathparse{\l@tmp@count/\l@tmp@total*360}
		\let\angle@b=\pgfmathresult
		\ifthenelse{\equal{\angle@a}{\angle@b}}{}{
			\pgfmathparse{(\angle@a+\angle@b)/2}
			\let\angle@c=\pgfmathresult
			\draw[fill=##3]
				(0,0) --
				(\angle@a:1) arc (\angle@a:\angle@b:1)
				-- cycle;
			\node
				[label=\angle@c:##1,inner sep=0pt,outer sep=0pt]
				at (\angle@c:1) {};
		}
	}%
	\fbox{\vbox{%
		\hbox{\bf#1}\vspace{5pt}%
		\hbox{\begin{tikzpicture}\graf@stats\end{tikzpicture}}%
	}}%
	\endgroup%
}

\newcommand\manus@grafer{%
	\par
	\manus@graf@num{Repliker}{\manus@graf@repliker}
	\manus@graf@num{Repliker+Agerande}{\manus@graf@total}
	\par\vspace{8pt}
	\manus@graf@num{Kupletter}{\manus@graf@kupletter}
	\manus@graf@dim{Kupletter (bal.)}{\manus@graf@kupletter@l}
	\par\vspace{8pt}
	\manus@graf@dim{Repliker (cm)}{\manus@graf@repliker@l}
	\manus@graf@dim{Närvaro (cm)}{\manus@graf@narvaro@l}
	\par\vspace{8pt}
	\manus@graf@dim{Subspel (cm)}{\manus@graf@subspel@l}
	\manus@graf@dim{Närvaro+Subspel (cm)}{\manus@graf@total@l}
}



%%%%%%%%%% Replikrader %%%%%%%%%%

% manus@radavstandr
%
% Ett hjälpkommando som ser till att raderna får rätt storlek och avstånd.
\newcommand\manus@hjalpavstand{%
	\raisebox{-3pt}[1em][3pt]{}%
}

% Temporär låda för att beräkna storleken på replikinnehållet.
\newsavebox{\manus@innehall@tmpbox}

%% sl@line{namn}{text}
%
% Huvudkommandot som skriver ut en repliksrad.
\newcommand\manus@skrivrad[4]{%
	% Räkna ny rad.
	\stepcounter{manus@radnummer}%
	% Spara tillfälligt undan innehållet i en låda.
	\savebox{\manus@innehall@tmpbox}{%
		\parbox{\manus@textbredd}{%
			\manus@hjalpavstand#2\manus@hjalpavstand}}%
	% Räkna ut längder från innehållsstorleken.
	\setlength{\manus@radstorlek}{\ht\manus@innehall@tmpbox}%
	\addtolength{\manus@radstorlek}{\dp\manus@innehall@tmpbox}%
	\setlength{\manus@indhojd}{\manus@radstorlek}%
	\addtolength{\manus@indhojd}{\manus@radavstand}%
	% Skriv ut en rad.
	\hbox{%
		% Nummer:
		\hspace{-\manus@numbredd}%
		\vbox to \manus@radstorlek{\hbox to \manus@numbredd{%
			\hfil% För högerjustering.
			\manus@hjalpavstand%
			\themanus@radnummer%
			\manus@hjalpavstand%
			\hspace{\manus@kolavstand}%
		}\vfil}%
		% Namn:
		\vbox to \manus@radstorlek{\hbox to \manus@namnbredd{%
			\color{#3}%
			\manus@hjalpavstand#1\manus@hjalpavstand%
		\hfil}\vfil}%
		% Innehåll:
		\vbox to \manus@radstorlek{\hbox to \manus@textbredd{%
				\parbox{\manus@textbredd}{%
					%\raggedright%
					\color{#3}%
					\manus@hjalpavstand#2\manus@hjalpavstand%
				}%
		\hfil}\vfil}%
		% Indikatorer:
		\ifthenelse{\equal{#4}{true}}{%
			\raisebox{\manus@indskift}[0pt][0pt]{%
				\hspace{\manus@kolavstand}%
				\manus@ritainds%
			}%
		}{}%
	}%
	\vspace{\manus@radavstand}% Extra radavstånd.
	\addtolength{\manus@aktlangd}{\manus@indhojd}% Lägg till höjden till aktlängden.
}



%%%%%%%%%% Automatiska beräkningar %%%%%%%%%%

% Öka bredden för karaktärsnamnskolumnen så långt som behövs.
% Notera att om \manus@namnbredd har sats till ett större värde innan
% \begin{document} så görs ingenting.
\AtBeginDocument{%
	\ifdim\sl@maxnamewd>\manus@namnbredd%
		\setlength{\manus@namnbredd}{\sl@maxnamewd}%
	\fi%
}

% Räkna ut den tillåtna bredden på repliktextskolumnen.
\AtBeginDocument{\manus@beraknabredd}

% Stäng av vissa kommandon som bara skall få förekomma i preamblen.
\AtBeginDocument{%
	\global\def\nyroll{\errmessage{%
		\textbackslash nyroll får bara användas i preamblen.}}%
	\global\def\nyhjalproll{\errmessage{%
		\textbackslash nyhjalproll får bara användas i preamblen.}}%
}



%%%%%%%%%% Sidfötter %%%%%%%%%%

%% \fotstil
%
% Detta kommando används för att formattera inlästa sidfötter i de sidlayouter
% som skapas av \fotfil. Detta kommando kan ta en parameter eller ingen alls,
% men aldrig flera.
\let\fotstil\textit

%% \fotstil@yttre
%
% Detta kommando används för att formattera inlästa sidfötter i de sidlayouter
% som skapas av \fotfil. Detta kommando kan ta en parameter eller ingen alls,
% men aldrig flera.
%
% Till skillnad från \fotstil som används innan sidfoten expanderas, så
% appliceras detta kommando på varje rad (se \manus@fotstil nedan).
\def\fotstil@yttre#1{#1}

%% \manus@fotstil
%
% Detta kommando plockar isär en paragrafs rader och applicerar \fotstil@yttre
% kommandot på varje rad för sig. Detta är till exempel användbart då
% \fotstil@yttre är satt till \fbox, \underline eller dylikt.
\def\manus@fotstil{%
	\setbox0=\lastbox%
	\ifvoid0%
		\noindent\ignorespaces%
	\else%
		\unskip\unpenalty%
		\begingroup\manus@fotstil\\\endgroup%
		\hbox{\fotstil@yttre{\unhbox0}}%
	\fi%
}

%% \fotfil[layoutnamn]{filnamn}
%
% Skapa en ny sidlayout med givet namn som läser sidfötter från den givna filen.
% Sätt sedan den använda sidlayouten till den nyskapade.
\newcommand\fotfil[2][fotfil]{%
	\@ifundefined{ps@#1}{%
		\expandafter\newread\csname ps@#1@read\endcsname%
		\expandafter\openin\csname ps@#1@read\endcsname=#2%
		\def\default@fot{\hfil\thepage}%
		\expandafter\def\csname ps@#1\endcsname{%
			\def\@oddfoot{%
				\ifeof\csname ps@#1@read\endcsname%
					\def\@sidfot{}%
				\else%
					\expandafter\read\csname ps@#1@read\endcsname to \@sidfot%
				\fi%
				\thepage%
				\hfill%
				\parbox{0.8\textwidth}{%
					\raggedleft%
					\fotstil\@sidfot%
					\par\manus@fotstil%
				}%
			}%
			\def\@evenfoot{%
				\ifeof\csname ps@#1@read\endcsname%
					\def\@sidfot{}%
				\else%
					\expandafter\read\csname ps@#1@read\endcsname to \@sidfot%
				\fi%
				\parbox{0.8\textwidth}{%
					\fotstil\@sidfot%
					\par\manus@fotstil%
				}%
				\hfill%
				\thepage%
			}%
		}%
		\pagestyle{#1}%
	}{%
		\errmessage{Detta layoutnamn används redan.}%
	}%
}
