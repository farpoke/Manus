% Version 1&2: Cecilia Kjellman, cecilia.kjellman@gmail.com
% Version 2: Anton Mårtensson, anton.v.martensson@gmail.com

\NeedsTeXFormat{LaTeX2e}[1994/06/01]
\ProvidesClass{manus}[2012/05/21]



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

% Sätt några defaultvärden.
\setlength{\manus@numbredd}{3em}
\setlength{\manus@namnbredd}{0pt} % Denna längd räknas om senare.
\setlength{\manus@indskift}{0pt}
\setlength{\manus@indbredd}{10pt}
\setlength{\manus@radavstand}{5pt}
\setlength{\manus@kolavstand}{1em}
\setlength{\manus@stat@kolbredd}{3.2em}

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

% Räknare för beräkning av antal rander för subspelsindikatorer.
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
			\csname#1gr\endcsname{#1 kommer in på scen.}}}%
		\expandafter\newcommand\csname#1ut\endcsname{%
			\setboolean{#1@in}{false}%
			\@ifstar{}{%
			\csname#1gr\endcsname{#1 går av scen.}}}%
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
%% \deltagare{deltagare}     : Ange deltagare i denna kuplett.
%% \beskrivning{beskrivning} : Ange beskrivning för denna kuplett.
%% \melodi{melodi}           : Ange melodiförslag för denna kuplett.
%
%% \end{kuplett}
\newenvironment{kuplett}{%
	% Deklarera kommandon för kuplettinformation.
	\newcommand{\titel}[1]{\def\ktitel{##1}}%
	\newcommand{\deltagare}[1]{\xdef\kdeltagare{##1}}%
	\newcommand{\beskrivning}[1]{%
		\def\kbeskrivning{##1}%
	}%
	\newcommand{\melodi}[1]{\def\kmelodi{##1}}%
	% Sätt alla värden till tomrum.
	\titel{}%
	\deltagare{}%
	\beskrivning{}%
	\melodi{}%
	% Om deltagare inte specificeras antags alla som är på scen delta.
	\begingroup%
	\def\\##1\\##2\\##3\\##4\\##5{% \\{namn}\\{utskriftnamn}\\{ind}\\{sub}\\{färg}
		\ifthenelse{\boolean{##3}}{%
			\ifx\kdeltagare\empty%
				\deltagare{##2}%
			\else%
				\deltagare{\kdeltagare, ##2}%
			\fi%
		}{}%
	}%
	\manus@statistik%
	\endgroup%
}{%
	% Lägg till ny subsection för kupletten.
	\subsection*{\hspace{\manus@numbredd}\Large\textcolor{kuplettfarg}{%
		Kuplett: \MakeUppercase{\ktitel}%
	}}%
	\addcontentsline{toc}{subsubsection}{%
		\textcolor{kuplettfarg}{\MakeUppercase{\ktitel}}\\%
		Deltagare: \emph{\kdeltagare}%
	}%
	% Lägg till kuplettbeskrivning i sammanfattningslistan.
	\manus@sfnykuplett{\ktitel}{\kbeskrivning}{\kdeltagare}%
	% Skriv ut information om kupletten.
	\enkelrad{%
		Melodiförslag: \emph{\kmelodi}\\%
		\texttt{Melodi:}\\%
		Deltagare: \emph{\kdeltagare}\\%
		Beskrivning: \emph{\kbeskrivning}%
	}\vspace{1em}%
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
	\printindex%
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
}

%% \manus@ritaind{färg}{overlay}
%
% Skriv ut ett indikatorblock med den givna färgen och med overlay om
% booleanen overlay är sann.
\newcommand\manus@ritaind[2]{%
	\color{#1}\rule{\manus@indbredd}{\manus@indhojd}%
	\ifthenelse{\boolean{#2}}{%
		\begin{tikzpicture}[overlay,x=15pt,y=15pt]
			\clip[xshift=1pt,yshift=0.1pt]
				(-\manus@indbredd,-0.2pt)
				rectangle (-2pt,\manus@indhojd) ;
			\foreach \i in {0,...,\value{manus@randantal}}
			{
				\path [draw,white,line width=5pt]
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
		\addtolength{\manus@randtmp}{15pt}%
		\stepcounter{manus@randantal}%
	\repeat%
	\stepcounter{manus@randantal}% Lägg till en extra för marginal.
	% Lägg till indikatorhöjden till skiftlängden.
	\global\addtolength{\manus@randskift}{\manus@indhojd}%
	% Räkna ner skiftet tills vi är under eller lika med noll igen.
	\loop\ifdim\manus@randskift>0pt%
		\global\addtolength{\manus@randskift}{-15pt}%
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
	\expandafter\newdimen\csname#1@stat@narvaro\endcsname%
	\expandafter\newdimen\csname#1@stat@subspel\endcsname%
	% Sätt alla värden till noll.
	\setcounter{#1@stat@repliker}{0}%
	\setcounter{#1@stat@kupletter}{0}%
	\setcounter{#1@stat@agerande}{0}%
	\setcounter{#1@stat@narvaro}{0}%
	\setcounter{#1@stat@subspel}{0}%
	\setlength{\csname#1@stat@repliker\endcsname}{0pt}%
	\setlength{\csname#1@stat@narvaro\endcsname}{0pt}%
	\setlength{\csname#1@stat@subspel\endcsname}{0pt}%
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
				\global\addtolength%
					{\csname##1@stat@subspel\endcsname}%
					{\manus@indhojd}%
			}{%
				\stepcounter{##1@stat@narvaro}%
				\global\addtolength%
					{\csname##1@stat@narvaro\endcsname}%
					{\manus@indhojd}%
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
	\def\\##1\\##2\\##3\\##4\\##5{% \\{namn}\\{utskriftnamn}\\{ind}\\{sub}\\{färg}
		\ifthenelse{\boolean{##3}}{%
			\stepcounter{##1@stat@kupletter}%
		}{}%
	}%
	\manus@statistik%
	\endgroup%
}

% Skapa en ny lista med lite aktstatistik.
\NewList\manus@akter

%% \manus@aktstatistik
%
%% Lägg till nuvarande akten i aktstatistiken om aktens längd är positiv.
\newcommand\manus@aktstatistik{\ifdim\manus@aktlangd>0pt%
	\edef\tmp{\theakt}
	\expandafter\Append\tmp\To\manus@akter%
	\edef\tmp{\the\manus@aktlangd}%
	\expandafter\Append\tmp\To\manus@akter%
\fi}

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
	\newcommand\kol@titel[1]{\hbox to \manus@stat@kolbredd{\hfil%
		\begin{rotate}{30}##1\end{rotate}%
	\hfil}}%
	\newcommand\stat@kol[1]{%
		\vbox to \baselineskip{\vfil%
			\hbox to \manus@stat@kolbredd{\hfil##1\hfil}}}%
	\renewcommand\vline{%
		\kern -0.5pt%
		\raisebox{-3pt}[0pt][0pt]{\rule{1pt}{\baselineskip}}%
		\kern -0.5pt%
	}%
	% Skriv ut titelrad.
	\vspace{3em}%
	\hbox{\bf%
		\hspace{1.2\manus@namnbredd}%
		\kol@titel{Repliker}%
		\kol@titel{Agerande}%
		\kol@titel{Total}%
		\kol@titel{Kupletter}%
		\kol@titel{Närvaro}%
		\kol@titel{Subspel}%
		\kol@titel{Total}%
		\kol@titel{Repliker ({\small $\approx$cm})}%
		\kol@titel{Närvaro ({\small $\approx$cm})}%
		\kol@titel{Subspel ({\small $\approx$cm})}%
		\kol@titel{Total ({\small $\approx$cm})}%
	}%
	% Skriv ut statistikrader.
	\def\\##1\\##2\\##3\\##4\\##5{% \\{namn}\\{utskriftnamn}\\{ind}\\{sub}\\{färg}
		\hbox{%
			\vbox to \baselineskip{\vfil\hbox to 1.2\manus@namnbredd{%
				\raisebox{0pt}[\baselineskip][0pt]{%
					\textbf{\textcolor{##5}{##2}}%
				}%
			\hfil}}%
			\vline%
			\stat@kol{\number\value{##1@stat@repliker}}%
			\stat@kol{\number\value{##1@stat@agerande}}%
			\stat@kol{%
				\number\numexpr%
					\value{##1@stat@repliker}+%
					\value{##1@stat@agerande}%
			}%
			\vline%
			\stat@kol{\number\value{##1@stat@kupletter}}%
			\vline%
			\stat@kol{\number\value{##1@stat@narvaro}}%
			\stat@kol{\number\value{##1@stat@subspel}}%
			\stat@kol{%
				\number\numexpr%
					\value{##1@stat@narvaro}+%
					\value{##1@stat@subspel}%
			}%
			\vline%
			\stat@kol{%
				\setlength%
					{\manus@stat@tmp}%
					{\csname##1@stat@repliker\endcsname}%
				\pgfmathtruncatemacro\stat@cm%
					{round(0.0351459804*\manus@stat@tmp)}%
				\stat@cm%
			}%
			\vline%
			\stat@kol{%
				\setlength%
					{\manus@stat@tmp}%
					{\csname##1@stat@narvaro\endcsname}%
				\pgfmathtruncatemacro\stat@cm%
					{round(0.0351459804*\manus@stat@tmp)}%
				\stat@cm%
			}%
			\stat@kol{%
				\setlength%
					{\manus@stat@tmp}%
					{\csname##1@stat@subspel\endcsname}%
				\pgfmathtruncatemacro\stat@cm%
					{round(0.0351459804*\manus@stat@tmp)}%
				\stat@cm%
			}%
			\stat@kol{%
				\setlength%
					{\manus@stat@tmp}%
					{\csname##1@stat@narvaro\endcsname}%
				\addtolength%
					{\manus@stat@tmp}%
					{\csname##1@stat@subspel\endcsname}%
				\pgfmathtruncatemacro\stat@cm%
					{round(0.0351459804*\manus@stat@tmp)}%
				\stat@cm%
			}%
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
	\ifthenelse{\boolean{grafer}}{\vspace{3em}\manus@grafer}{}%
}



%%%%%%%%%% Grafer %%%%%%%%%%

\newcommand\manus@grafer{
	\subsection*{Grafer}
	\begingroup
	\let\replik@stats\empty
	\def\\##1\\##2\\##3\\##4\\##5{% \\{namn}\\{utskriftnamn}\\{ind}\\{sub}\\{färg}
		\tmp@toks@a=\expandafter{\replik@stats}
		\tmp@toks@b={\\{##2}\\{\arabic{##1@stat@repliker}}\\{##5}}
		\edef\replik@stats{\the\tmp@toks@a\the\tmp@toks@b}
	}
	\manus@statistik
	\newcounter{tmp@total}
	\newcounter{tmp@count}
	\def\\##1\\##2\\##3{\addtocounter{tmp@total}{##2}}
	\replik@stats
	\def\\##1\\##2\\##3{
		\pgfmathparse{360*\value{tmp@count}/\value{tmp@total}}
		\let\angle@a=\pgfmathresult
		\addtocounter{tmp@count}{##2}
		\pgfmathparse{360*\value{tmp@count}/\value{tmp@total}}
		\let\angle@b=\pgfmathresult
		\pgfmathparse{(\angle@a+\angle@b)/2}
		\let\angle@c=\pgfmathresult
		\draw[fill=##3] (0,0) -- (\angle@a:1) arc (\angle@a:\angle@b:1) -- cycle;
		\node at (\angle@c:1.5) {##1};
	}
	\begin{tikzpicture}\replik@stats\end{tikzpicture}
	\endgroup
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
	\savebox{\manus@innehall@tmpbox}{
		\parbox{\manus@textbredd}{%
			\manus@hjalpavstand#2\manus@hjalpavstand}}%
	% Räkna ut längder från innehållsstorleken.
	\setlength{\manus@radstorlek}{\ht\manus@innehall@tmpbox}%
	\addtolength{\manus@radstorlek}{\dp\manus@innehall@tmpbox}%
	\setlength{\manus@indhojd}{\manus@radstorlek}
	\addtolength{\manus@indhojd}{\manus@radavstand}
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
		\ifthenelse{\equal{#4}{true}}{
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
