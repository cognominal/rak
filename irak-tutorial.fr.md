# irak pour les grands débutants

Un tutoriel sur irak, le shell interactif de rak, pour qui n'a jamais programmé ni
jamais utilisé de terminal. À la fin, vous saurez vous déplacer parmi les fichiers d'un
ordinateur, lancer des programmes, construire et parcourir des données imbriquées,
faire circuler des données entre fichiers, programmes et services web, et vous saurez
pourquoi chacune de ces choses fonctionne comme elle fonctionne.

rak est à la fois un langage et un shell. irak (prononcé « aï-rak ») est rak utilisé de
façon interactive : vous tapez, il répond. Tout ce tutoriel se passe dans irak.

## Sommaire

- [Préface](#préface)
- **Partie I : la machine**
  - [1. Terminal, shell et irak](#1-terminal-shell-et-irak)
  - [2. Fichiers et répertoires](#2-fichiers-et-répertoires)
  - [3. Processus](#3-processus)
- **Partie II : parler à irak**
  - [4. Valeurs, mots et chaînes](#4-valeurs-mots-et-chaînes)
  - [5. Commandes](#5-commandes)
  - [6. Le topique et l'historique](#6-le-topique-et-lhistorique)
- **Partie III : les données**
  - [7. Variables et sigils](#7-variables-et-sigils)
  - [8. Structures de données complexes](#8-structures-de-données-complexes)
  - [9. Parcourir les structures de données](#9-parcourir-les-structures-de-données)
  - [10. Désigner les données : noms, conteneurs, partage](#10-désigner-les-données--noms-conteneurs-partage)
- **Partie IV : déplacer les données**
  - [11. Redirection et formats](#11-redirection-et-formats)
  - [12. Pipelines](#12-pipelines)
  - [13. Le web comme un fichier : les cibles URL](#13-le-web-comme-un-fichier--les-cibles-url)
- **Partie V : tout assembler**
  - [14. Une session complète](#14-une-session-complète)
  - [15. D'irak à un script `.rak`](#15-dirak-à-un-script-rak)
  - [16. Pour aller plus loin](#16-et-ensuite-)
- **Annexes**
  - [A. rak et Raku, chapitre par chapitre](#annexe-a--rak-et-raku-chapitre-par-chapitre)
  - [B. Pièges](#annexe-b--les-pièges)
  - [C. Mini-glossaire](#annexe-c--mini-glossaire)

---

## Préface

### À qui s'adresse ce tutoriel

Il suffit de savoir taper au clavier et ouvrir une application sur votre ordinateur.
C'est tout. Inutile de savoir ce qu'est un « terminal », un « système de fichiers » ou
une « variable » : chaque mot est expliqué la première fois qu'il apparaît, et repris
dans le [mini-glossaire](#annexe-c--mini-glossaire) à la fin.

Si vous programmez déjà, survolez la partie I et lisez l'[annexe A](#annexe-a--rak-et-raku-chapitre-par-chapitre)
en parallèle : elle donne l'écriture Raku de chaque construction rak.

### Pourquoi apprendre dans un shell

La plupart des tutoriels de programmation vous font écrire un fichier, l'exécuter, lire
le résultat, modifier le fichier, puis l'exécuter à nouveau. irak réduit cette boucle à
une ligne : vous tapez quelque chose, appuyez sur ENTRÉE, et voyez aussitôt ce que cela
signifie. C'est donc un bon endroit pour *poser des questions à l'ordinateur* : que
contient ce répertoire, que contient ce fichier, que répond ce service web, quel est le
troisième élément de cette liste. La programmation commence par une conversation, et
devient un programme quand la conversation mérite d'être gardée
([chapitre 15](#15-dirak-à-un-script-rak)).

### Comment lire ce tutoriel

Lisez-le dans l'ordre, au clavier. Chaque exemple est fait pour être tapé. Les chapitres
s'appuient les uns sur les autres et, à partir du [chapitre 8](#8-structures-de-données-complexes),
ils réutilisent le même petit fichier de données, `team.json`, que vous construirez
vous-même.

Chaque chapitre se termine par un **Résumé** et quelques **Exercices**. Les réponses sont
repliées sous chaque exercice : essayez d'abord, dépliez ensuite.

### Travaux en cours

rak et irak sont jeunes, et ce tutoriel a un peu d'avance sur eux. Il décrit rak tel
qu'il est conçu, ce qui correspond le plus souvent, mais pas toujours, à son
comportement actuel. Là où les deux diffèrent, un encadré rouge comme celui-ci le
signale :

> [!CAUTION]
> 🔴 **Pas encore implémenté.** La fonctionnalité décrite ici n'existe pas encore : les
> exemples échoueront avec une erreur.

> [!CAUTION]
> 🔴 **Ne se comporte pas (encore) comme décrit.** La fonctionnalité existe, mais elle
> donne aujourd'hui un autre résultat, ou une erreur, dans le cas montré.

Les plus grands écarts sont dans le chapitre web
([chapitre 13](#13-le-web-comme-un-fichier--les-cibles-url)) : lire depuis des URL et
publier vers elles fonctionne, mais la routine `http` pour les autres sortes de requêtes,
le suivi des pages et les réponses binaires sont conçus, pas implémentés. Tout ce qui
n'est pas dans un encadré rouge a été vérifié sur le rak actuel.

Les messages de rak et d'irak sont en anglais ; les exemples les montrent tels quels.

### Conventions

Une session irak est présentée ainsi :

```
[0] > say hello
hello
[1] > 1 + 2
3
```

- `[0] >` est l'**invite** (*prompt*) d'irak : irak vous attend. Le nombre compte ce que
  vous avez tapé jusque-là. Vous tapez ce qui suit l'invite, puis ENTRÉE.
- Les lignes sans invite sont la réponse d'irak. Vous ne les tapez pas.
- Le texte qui suit `#` et une espace est un **commentaire** : une note pour le lecteur
  humain, ignorée par irak. Inutile de taper les commentaires.

```
[2] > 10 * 3          # cette note est ignorée
30
```

Quand les numéros de l'invite n'ont pas d'importance, les exemples montrent `>` seul.

Parfois, une commande est destinée à votre terminal habituel, avant le lancement
d'irak. Ces lignes commencent par `$` :

```
$ ./rak
```

Les touches sont écrites en capitales : ENTRÉE, TAB, Ctrl-C (maintenir Ctrl, appuyer
sur C), Ctrl-D, ↑ et ↓.

---

# Partie I : la machine

Avant de parler utilement à un ordinateur, il faut se faire une image de ce qu'il
contient : des fichiers conservés sur disque, et des programmes qui tournent en mémoire.
La partie I vous donne cette image.

## 1. Terminal, shell et irak

### 1.1 Un terminal est une fenêtre, un shell est un programme

Sur un ordinateur moderne, on *pointe* surtout : on clique sur des icônes, on déplace
des fenêtres, on choisit dans des menus. Un **terminal** est une fenêtre où l'on *tape*
à la place. Il affiche des lignes de texte et, en bas, l'endroit où apparaît ce que vous
tapez.

Un terminal ne fait rien par lui-même. Il affiche du texte, et transmet ce que vous
tapez à un programme qui tourne à l'intérieur. Ce programme est un **shell** : il lit
une ligne que vous tapez, fait ce qu'elle dit, affiche le résultat, et attend la ligne
suivante. Les shells habituels s'appellent bash, zsh ou fish. irak est aussi un shell,
avec une différence : c'est en même temps un vrai langage de programmation, si bien que
la même ligne peut lister des fichiers, calculer une somme ou remodeler des données
récupérées sur le web. Un shell traditionnel a besoin de programmes auxiliaires, comme
`jq` pour les données JSON et `curl` pour le web, pour faire ce qu'irak fait seul ;
la section [13.11](#1311-ce-dont-un-shell-traditionnel-aurait-besoin) compare les deux côte à
côte, une fois que vous en saurez assez pour apprécier la différence.

La boucle que fait tourner un shell a un nom : **lire, évaluer, afficher, recommencer**,
en anglais *read, evaluate, print, loop*, ou **REPL**. irak est la REPL de rak.

### 1.2 Lancer irak

Ouvrez un terminal. Sous Linux, il s'appelle en général « Terminal » ; sous macOS, c'est
Terminal.app, dans Applications → Utilitaires. Vous voyez une ligne qui se termine par
`$` ou `%` : l'invite de votre shell habituel.

Si rak est installé, lancez irak avec :

```
$ rak
```

Si vous avez compilé rak depuis son code source, allez dans le répertoire où vous l'avez
compilé et tapez :

```
$ ./rak
```

(Le `./` signifie « le programme appelé `rak` *ici même* ». Le [chapitre 2](#2-fichiers-et-répertoires)
explique pourquoi c'est nécessaire.)

irak vous salue et affiche son invite :

```
Welcome to irak, the rak shell.
[0] >
```

Le `[0]` compte vos **soumissions** : chaque fois que vous appuyez sur ENTRÉE, ce que
vous avez tapé est soumis à irak, qui l'évalue, et le compteur augmente d'un.

### 1.3 Votre première soumission

Tapez ceci, puis ENTRÉE :

```
[0] > say hello
hello
```

`say` est une **routine** : un comportement nommé, intégré à rak. `say` affiche ce qui
le suit, puis passe à la ligne. `hello` est ce qu'il affiche.

Essayez-en quelques autres :

```
[1] > say 'hello world'
hello world
[2] > say 42
42
[3] > 6 * 7
42
```

La dernière n'a pas de `say`, et irak affiche quand même `42`. irak montre la **valeur**
de chaque soumission : le résultat de ce que vous avez tapé. `6 * 7` a pour valeur `42`,
donc irak l'affiche. `say hello` *affiche* `hello` lui-même, donc irak n'ajoute rien.
Le [chapitre 4](#4-valeurs-mots-et-chaînes) revient sur cette différence.

Pourquoi des apostrophes autour de `'hello world'` ? Sans elles, `say` reçoit deux mots
séparés, `hello` et `world`, et les affiche l'un après l'autre, sans rien entre eux :

```
[4] > say hello world
helloworld
```

Les apostrophes font de `hello world` un seul morceau de texte, espace comprise. Le
[chapitre 4](#43-chaînes--nues-et-entre-guillemets) explique quand elles sont nécessaires.

### 1.4 Sortir, interrompre, se débloquer

- **Ctrl-D** sur une invite vide quitte irak. Vous revenez à votre shell habituel.
- **Ctrl-C** arrête ce qui est en cours et vous rend l'invite. Sur l'invite elle-même,
  il efface la ligne en cours de frappe. Il ne fait jamais quitter irak.
- Si irak affiche une autre invite, faite de points, c'est qu'il pense que votre
  soumission n'est pas finie : vous avez ouvert une parenthèse ou un guillemet sans le
  fermer. Fermez-le et appuyez sur ENTRÉE, ou faites Ctrl-C pour recommencer.

```
[5] > say (1 + 2
...   )
3
```

### 1.5 Les erreurs ne coûtent rien

Vous ne pouvez pas casser irak en tapant quelque chose de faux. Quand il ne comprend pas
une soumission, ou la comprend mais ne peut pas l'exécuter, il affiche un **message
d'erreur** et attend la soumission suivante. Rien d'autre ne se passe.

```
[6] > 1 +
===SORRY!=== Error while compiling
Missing required term after infix
------> 1 +⏏<EOL>
```

Un message d'erreur a l'air effrayant, mais il est écrit pour vous. Lisez-le en trois
temps :

1. **Quel genre d'erreur** : `===SORRY!=== Error while compiling` signifie qu'irak n'a
   même pas pu comprendre la ligne. D'autres erreurs surviennent plus tard, pendant
   l'exécution de la ligne (par exemple, un fichier qui n'existe pas).
2. **Ce qui ne va pas** : `Missing required term after infix`, « terme manquant après
   l'infixe ». Un *infixe* est un opérateur écrit entre deux choses, comme `+`. irak a
   vu `1 +` et attendait un second nombre.
3. **Où** : le signe `⏏` marque l'endroit. Ici, la fin de la ligne (`<EOL>` signifie
   *end of line*, « fin de ligne »).

Corrigez ensuite la ligne et réessayez. La touche ↑ rappelle votre soumission
précédente, pour la corriger sans tout retaper.

### Résumé

- Un terminal est une fenêtre de texte. Un shell est un programme qui y lit et exécute
  vos lignes.
- irak est le shell de rak. Lancez-le avec `rak` ou `./rak`, quittez-le avec Ctrl-D.
- Chaque ligne soumise a une valeur, qu'irak affiche sauf si la ligne a déjà affiché
  quelque chose.
- Les messages d'erreur disent quel genre d'erreur, ce qui ne va pas, et où (`⏏`).

### Exercices

1. Lancez irak et calculez combien de secondes compte une journée.
   <details><summary>Réponse</summary>

   ```
   > 24 * 60 * 60
   86400
   ```
   </details>

2. Affichez `good morning` avec `say`. Combien de mots `say` a-t-il reçus ?
   <details><summary>Réponse</summary>

   `say 'good morning'` affiche `good morning` : `say` a reçu un seul morceau de texte.
   `say good morning` affiche `goodmorning` : `say` a reçu deux mots, `good` et
   `morning`, et les a affichés l'un après l'autre.
   </details>

3. Tapez `say (2 + 3` puis ENTRÉE. Que fait irak ? Comment en sortir ?
   <details><summary>Réponse</summary>

   irak affiche son invite de continuation (`...`), car la parenthèse est encore
   ouverte. Tapez `)` puis ENTRÉE pour terminer la soumission, ou Ctrl-C pour
   l'abandonner.
   </details>

---

## 2. Fichiers et répertoires

### 2.1 L'arbre

Tout ce qu'un ordinateur conserve une fois éteint est stocké dans des **fichiers** : vos
photos, vos documents, et les programmes eux-mêmes. Un fichier est une suite d'octets
qui porte un nom. Un **octet** est un nombre entre 0 et 255 ; texte, images et
programmes sont tous faits d'octets, interprétés différemment.

Les fichiers sont rangés dans des **répertoires** (aussi appelés dossiers). Un
répertoire contient des fichiers et d'autres répertoires, qui contiennent d'autres
fichiers et répertoires, et ainsi de suite. Le résultat est un **arbre**, dessiné à
l'envers : sa racine est en haut.

```
/                       le répertoire racine
├── home
│   └── ada             votre répertoire personnel
│       ├── notes.txt
│       ├── photos
│       │   └── cat.jpg
│       └── projects
│           └── rak
├── tmp
└── usr
    └── bin             où vivent de nombreux programmes
        ├── ls
        └── git
```

Sous Linux et macOS, la racine de l'arbre s'écrit `/`. (Windows l'écrit autrement ; ce
tutoriel suit Linux et macOS.)

Votre **répertoire personnel** (*home directory*) est la partie de l'arbre qui vous
appartient. Il porte votre nom d'utilisateur, et c'est en général `/home/votrenom` sous
Linux ou `/Users/votrenom` sous macOS. Dans ce tutoriel, l'utilisatrice s'appelle `ada`.

### 2.2 Chemins

Un **chemin** désigne un endroit de l'arbre en listant les répertoires qui y mènent,
séparés par `/` :

```
/home/ada/photos/cat.jpg
```

se lit : depuis la racine `/`, entrer dans `home`, puis dans `ada`, puis dans `photos`,
et y prendre le fichier `cat.jpg`.

Un chemin qui commence par `/` est **absolu** : il part de la racine, et signifie donc
la même chose où que vous soyez. Un chemin qui ne commence pas par `/` est **relatif** :
il part du **répertoire courant**, l'endroit de l'arbre où vous êtes maintenant. Chaque
shell, et chaque programme en cours d'exécution, a un répertoire courant.

Si votre répertoire courant est `/home/ada`, alors :

| Chemin relatif | Signifie |
|---|---|
| `notes.txt` | `/home/ada/notes.txt` |
| `photos/cat.jpg` | `/home/ada/photos/cat.jpg` |
| `.` | le répertoire courant lui-même, `/home/ada` |
| `..` | le répertoire au-dessus, `/home` |
| `../..` | deux niveaux plus haut, `/` |
| `./notes.txt` | la même chose que `notes.txt` |

Deux raccourcis de plus :

- `~` désigne votre répertoire personnel. `~/photos` est `/home/ada/photos`, où que vous
  soyez.
- `-`, dans `cd -`, signifie « le répertoire où j'étais avant » (voir plus bas).

Voilà pourquoi vous avez lancé irak avec `./rak` au [chapitre 1](#12-lancer-irak) :
quand vous tapez un nom de programme seul, le shell le cherche dans une liste de
répertoires spéciaux ([chapitre 3](#33-comment-un-programme-est-trouvé--path)), pas dans le
répertoire courant. `./rak` dit « le `rak` qui est ici ».

**Noms avec espaces.** Un fichier peut s'appeler `my notes.txt`. Mais un shell sépare
les mots par des espaces, donc `my notes.txt` ressemble à deux noms. Mettez un tel nom
entre apostrophes : `'my notes.txt'`. Beaucoup de gens évitent les espaces dans les noms
de fichiers et utilisent `-` ou `_` à la place : `my-notes.txt`.

### 2.3 Se déplacer

Lancez irak et demandez où vous êtes :

```
> pwd
/home/ada
```

`pwd` veut dire *print working directory*, « afficher le répertoire de travail »
(*répertoire de travail* est un autre nom du répertoire courant). irak démarre dans le
répertoire d'où vous l'avez lancé.

Listez ce qui s'y trouve :

```
> ls
notes.txt  photos  projects
```

Entrez dans un répertoire avec `cd` (*change directory*, « changer de répertoire ») :

```
> cd photos
> pwd
/home/ada/photos
> ls
cat.jpg
```

Remontez, avec `..` :

```
> cd ..
> pwd
/home/ada
```

Trois formes courtes valent la peine d'être retenues :

```
> cd /usr/bin       # un chemin absolu : y aller directement
> cd -              # revenir là où l'on était : /home/ada
> cd                # sans argument : rentrer à la maison
```

`cd -` est pratique quand vous passez sans cesse d'un endroit à un autre : il les
échange à chaque fois.

Vous pouvez aussi demander à rak le répertoire courant sous forme de valeur, plutôt que
de ligne affichée. `$*CWD` le contient :

```
> $*CWD
"/home/ada".IO
```

Ignorez le `.IO` pour l'instant : il indique que la valeur est un chemin, pas un texte
quelconque.

### 2.4 Regarder de plus près : `ls -l` et `ls -a`

`ls` accepte des **options** : des mots commençant par `-` qui modifient ce qu'il fait.
`-l` demande la liste détaillée (*long*) :

```
> ls -l
-rw-r--r-- 1 ada ada  1204 Nov 18 10:02 notes.txt
drwxr-xr-x 2 ada ada  4096 Nov 17 21:40 photos
drwxr-xr-x 3 ada ada  4096 Nov 19 09:15 projects
```

Chaque ligne décrit une entrée. En partant de la droite : le nom, la date de dernière
modification, la taille en octets, le groupe et le propriétaire (ici tous deux `ada`),
un compteur que vous pouvez ignorer, et dix caractères de **permissions**.

Le premier caractère dit de quel genre d'entrée il s'agit : `-` pour un fichier, `d`
pour un répertoire (*directory*). Les neuf autres vont par trois groupes de trois, pour
trois sortes de personnes :

```
- rw- r-- r--
  │   │   └── tous les autres
  │   └────── le groupe du fichier
  └────────── le propriétaire du fichier
```

Dans chaque groupe, `r` signifie *peut lire* (*read*), `w` *peut écrire* (*write*,
modifier) et `x` *peut exécuter* (*execute* : le lancer comme programme ou, pour un
répertoire, y entrer). Un `-` signale une permission absente. Ainsi `-rw-r--r--` est un
fichier que son propriétaire peut lire et modifier, et que tous les autres peuvent
seulement lire.

`-a` montre aussi les entrées **cachées**, dont le nom commence par un point :

```
> ls -a
.  ..  .config  notes.txt  photos  projects
```

On retrouve `.` et `..`, ainsi que `.config`, un répertoire où les programmes rangent
leurs réglages. Les options se combinent : `ls -la`.

### 2.5 Créer et supprimer

| Commande | Effet |
|---|---|
| `mkdir rép` | créer un répertoire |
| `touch fichier` | créer un fichier vide (ou mettre à jour la date d'un fichier existant) |
| `cp de vers` | copier un fichier |
| `mv de vers` | déplacer ou renommer un fichier ou un répertoire |
| `rm fichier` | supprimer un fichier |
| `rmdir rép` | supprimer un répertoire vide |
| `cat fichier` | afficher le contenu d'un fichier |

Créez un bac à sable pour ce tutoriel, pour que vos expériences restent au même
endroit :

```
> cd
> mkdir irak-tutorial
> cd irak-tutorial
> touch empty.txt
> ls
empty.txt
> mv empty.txt still-empty.txt
> ls
still-empty.txt
> rm still-empty.txt
> ls
>
```

Le dernier `ls` n'a rien affiché : le répertoire est vide.

> **Attention.** `rm` ne met pas le fichier à la corbeille. Le fichier a disparu, et il
> n'y a pas d'annulation. Avant de supprimer quelque chose, faites-en un `ls`, et lisez
> le nom deux fois.

Désormais, le tutoriel suppose que vous êtes dans `~/irak-tutorial`. Si vous quittez
irak et revenez, commencez par `cd ~/irak-tutorial`.

### 2.6 Texte, binaire et extensions

Certains fichiers contiennent du **texte** : des lettres, des chiffres, de la
ponctuation, des sauts de ligne. Vous pouvez les lire avec `cat` et les modifier avec un
éditeur de texte. D'autres sont **binaires** : images, sons, programmes compilés. Leurs
octets ne sont pas faits pour être lus comme du texte, et `cat` n'en affiche que du
charabia.

Un nom de fichier se termine en général par une **extension** : un point et quelques
lettres, comme dans `notes.txt`, `cat.jpg`, `team.json`. L'extension n'est qu'une partie
du nom. Elle ne change pas le contenu du fichier, mais elle dit aux gens et aux
programmes à quoi s'attendre : `.txt` pour du texte brut, `.jpg` pour une image,
`.json` pour des données au format JSON.

rak prend les extensions au sérieux. Quand vous enregistrez des données dans
`team.json`, rak les écrit en JSON *parce que* le nom se termine par `.json` ; quand vous
les enregistrez dans `team.txt`, il écrit du texte brut. Le
[chapitre 11](#11-redirection-et-formats) y est entièrement consacré.

### Résumé

- Les fichiers contiennent des octets. Les répertoires contiennent des fichiers et des
  répertoires, formant un arbre dont la racine est `/`.
- Un chemin désigne un endroit de l'arbre. Les chemins absolus commencent par `/` ; les
  relatifs partent du répertoire courant. `.` est ici, `..` est au-dessus, `~` est chez
  vous.
- `pwd`, `ls`, `cd`, `mkdir`, `touch`, `cp`, `mv`, `rm`, `cat` couvrent le travail
  quotidien sur les fichiers.
- `ls -l` montre les permissions : lecture, écriture, exécution, pour le propriétaire,
  le groupe et les autres.
- `rm` est définitif.
- Une extension fait partie du nom ; rak s'en sert pour choisir un format.

### Exercices

1. Depuis `~/irak-tutorial`, quel chemin absolu désigne `../irak-tutorial/./x.txt` ?
   <details><summary>Réponse</summary>

   `/home/ada/irak-tutorial/x.txt` : `..` remonte à `/home/ada`, on redescend dans
   `irak-tutorial`, et `.` reste sur place.
   </details>

2. Créez les répertoires `a`, puis `a/b`, et un fichier `a/b/c.txt`. Puis entrez dans
   `a/b` et revenez à `~/irak-tutorial` en un seul `cd`.
   <details><summary>Réponse</summary>

   ```
   > mkdir a
   > mkdir a/b
   > touch a/b/c.txt
   > cd a/b
   > cd ../..
   ```
   `cd -` marcherait aussi, puisque vous veniez de là.
   </details>

3. Dans `ls -l`, une ligne commence par `-rwx------`. Qui peut faire quoi ?
   <details><summary>Réponse</summary>

   C'est un fichier (`-`). Son propriétaire peut le lire, le modifier et l'exécuter.
   Personne d'autre ne peut rien en faire.
   </details>

---

## 3. Processus

### 3.1 Programmes et processus

Un **programme** est un fichier : une liste d'instructions, posée sur le disque. `ls` est
un programme, dans le fichier `/usr/bin/ls`. Tant qu'il reste là, un programme ne fait
rien.

Un **processus** est un programme *en cours d'exécution* : l'ordinateur a chargé les
instructions en mémoire et les exécute. Un même programme peut tourner sous forme de
plusieurs processus à la fois. Trois terminaux qui font tourner irak, ce sont trois
processus irak, issus d'un seul fichier programme.

Chaque processus reçoit un numéro à son démarrage, son **identifiant de processus**, ou
**PID** (*process ID*). rak montre le sien :

```
> $*PID
48213
```

Votre numéro sera différent. `ps` liste les processus. Avec `-f`, il montre davantage de
colonnes :

```
> ps -f
UID        PID  PPID  C STIME TTY      TIME     CMD
ada      47990 47985  0 09:12 pts/3    00:00:00 -zsh
ada      48213 47990  1 09:20 pts/3    00:00:02 rakudo-m …
ada      48377 48213  0 09:31 pts/3    00:00:00 ps -f
```

`PPID` est le PID du **parent** : le processus qui a lancé celui-ci. Lisez le tableau en
partant du bas : `ps` (48377) a été lancé par irak (48213, affiché comme `rakudo-m`, le
programme qui exécute rak), lui-même lancé par votre shell habituel `zsh` (47990). Tout
processus, sauf le tout premier, a un parent ; les processus forment donc un arbre,
comme les fichiers. `pstree -p` le dessine, s'il est installé :

```
> pstree -p $*PID
rakudo-m(48213)───pstree(48391)
```

Quand irak exécute `ls`, il lance un **processus enfant**, attend qu'il se termine, puis
vous rend l'invite. La sortie de l'enfant va directement dans votre terminal.

### 3.2 Ce que porte chaque processus

Chaque processus possède, entre autres :

1. **Un répertoire courant.** Les chemins relatifs partent de là ([2.2](#22-chemins)).
2. **Un environnement** : un ensemble de valeurs textuelles nommées, appelées **variables
   d'environnement**, qu'il a reçues de son parent. Elles contiennent des réglages comme
   votre répertoire personnel ou votre langue.
3. **Trois flux standard**, numérotés 0, 1 et 2 :

   | Numéro | Nom | Branché d'habitude sur | Sert à |
   |---|---|---|---|
   | 0 | entrée standard | le clavier | ce que le processus lit |
   | 1 | sortie standard | le terminal | ses résultats normaux |
   | 2 | erreur standard | le terminal | messages d'erreur et avertissements |

   Un processus ne sait pas où vont ses flux, et ne s'en soucie pas. C'est ce qui rend
   possibles la [redirection](#11-redirection-et-formats) et les
   [pipelines](#12-pipelines) : le shell branche les flux sur des fichiers, ou sur
   d'autres processus, et le programme fonctionne de la même façon.
4. **Un statut de sortie**, qu'il laisse derrière lui en se terminant
   ([3.5](#35-comment-un-processus-se-termine)).

rak montre son environnement dans `%*ENV`. Le `%` indique qu'il s'agit d'une collection
d'entrées nommées ([chapitre 7](#7-variables-et-sigils)). Demandez une entrée avec un
point suivi de son nom :

```
> %*ENV.HOME
/home/ada
> %*ENV.USER
ada
> %*ENV.LANG
en_US.UTF-8
```

Le `.HOME` après `%*ENV` signifie « l'entrée nommée `HOME` ». Ce point s'appelle un
**indice pointé** (*dotty subscript*), et le [chapitre 9](#9-parcourir-les-structures-de-données)
lui est entièrement consacré.

Les trois flux standard sont aussi visibles depuis rak, sous les noms `$*IN`, `$*OUT` et
`$*ERR`. `say` écrit dans `$*OUT`. `note` écrit dans `$*ERR` :

```
> note 'something is odd'
something is odd
```

Dans le terminal, les deux se ressemblent. La différence apparaît quand vous envoyez
l'un d'eux dans un fichier : l'autre atteint toujours l'écran. Le
[chapitre 5](#56-redirections-de-commandes) le montre.

### 3.3 Comment un programme est trouvé : `$PATH`

Quand vous tapez `ls`, irak a besoin du fichier qui contient le programme `ls`. Il ne
fouille pas tout le disque. Il regarde la variable d'environnement `PATH` :

```
> %*ENV.PATH
/home/ada/.local/bin:/usr/local/bin:/usr/bin:/bin
```

`PATH` est une liste de répertoires séparés par `:`. irak cherche un fichier appelé `ls`
dans chacun d'eux, dans l'ordre, et exécute le premier qu'il trouve. Les programmes
trouvés ainsi s'appellent des **commandes externes**, parce qu'ils vivent hors d'irak.

La commande intégrée `type` dit ce que signifie un nom :

```
> type ls
ls is /usr/bin/ls
> type cd
cd is a shell builtin
> type say
say is a rak routine
```

`type` répond du point de vue de rak, et un nom peut signifier plusieurs choses. Le
[chapitre 5](#53-qui-lemporte-pour-un-nom) explique comment irak choisit.

Voilà pourquoi `./rak` avait besoin de son `./` : le répertoire où vous avez compilé rak
n'est pas dans `PATH`, donc le nom `rak` seul n'y serait pas trouvé.

### 3.4 Lancer un enfant

Une commande qui dure un moment montre qu'irak attend son enfant :

```
> sleep 3
>
```

`sleep 3` est une commande externe qui ne fait rien pendant trois secondes, puis se
termine. Pendant ces trois secondes, irak n'affiche pas d'invite : il attend. Quand
l'enfant se termine, l'invite revient.

Un enfant **hérite** de son parent : il reçoit une copie de l'environnement d'irak,
démarre dans le répertoire courant d'irak, et ses trois flux sont branchés sur le même
terminal. C'est pourquoi un programme plein écran fonctionne depuis irak :

```
> less ~/irak-tutorial/a/b/c.txt
```

`less` prend possession du terminal pour montrer le fichier un écran à la fois (appuyez
sur `q` pour quitter). Les éditeurs comme `nano` ou `vim` fonctionnent de la même façon.

### 3.5 Comment un processus se termine

Un processus se termine de l'une de deux façons :

- Il **sort** (*exits*) : il finit et rend un petit nombre, son **code de sortie**. Par
  convention, `0` signifie succès, et toute autre valeur un échec d'une sorte ou d'une
  autre. Chaque programme documente la signification de ses codes.
- Il est **tué par un signal** : quelque chose d'extérieur lui dit de s'arrêter
  ([3.7](#37-arrêter-un-processus)).

Dans les deux cas, le processus laisse un **statut de sortie** : son code de sortie, ou
le signal qui l'a tué. irak garde le dernier dans `$?`.

```
> ls nothing-here
ls: cannot access 'nothing-here': No such file or directory
exit 2
> $?->exitcode
2
> ls
a
> $?->exitcode
0
```

Quand une commande échoue, irak affiche une ligne grisée `exit N`, pour que vous le
remarquiez. Sinon, il ne dit rien. `$?` peut aussi être comparé directement à un
nombre : `$? == 0` est vrai après un succès.

`true` et `false` sont deux minuscules programmes qui ne font rien d'autre que réussir
et échouer. Ils sont utiles pour expérimenter :

```
> false
exit 1
> $? == 0
False
> true
> $? == 0
True
```

### 3.6 Pourquoi `cd` doit être intégré

Un enfant reçoit une *copie* du répertoire courant et de l'environnement de son parent.
Quoi que l'enfant fasse de sa copie, celle du parent reste inchangée. Un programme `cd`,
exécuté comme enfant, changerait donc seulement son propre répertoire, puis
sortirait : irak ne bougerait pas.

C'est pourquoi `cd` est une **commande intégrée** (*builtin*) : une commande qu'irak
exécute lui-même, dans son propre processus, sans lancer d'enfant. `type cd` le dit.
Tous les shells intègrent `cd` pour la même raison.

Il en va de même pour l'environnement. Modifier `%*ENV` dans irak le modifie pour irak
et pour tous les enfants lancés ensuite, mais pas pour le shell qui a lancé irak :

```
> %*ENV.GREETING = 'hi'
hi
> printenv GREETING
hi
```

`printenv` est un enfant qui affiche une variable d'environnement dont il a hérité.

### 3.7 Arrêter un processus

Un **signal** est un court message que le système envoie à un processus, en général
pour lui dire de s'arrêter. Chaque signal a un nom et un numéro :

| Signal | Numéro | Envoyé quand | Effet habituel |
|---|---|---|---|
| `SIGINT` | 2 | vous appuyez sur Ctrl-C | arrêt |
| `SIGTERM` | 15 | `kill PID` | arrêt propre |
| `SIGKILL` | 9 | `kill -9 PID` | arrêt immédiat, sans nettoyage possible |
| `SIGPIPE` | 13 | le lecteur de sa sortie a disparu | arrêt ([chapitre 12](#127-paresse-et-sigpipe)) |

Essayez Ctrl-C sur un long `sleep` :

```
> sleep 100
^C
killed by SIGINT
> $?->signal
2
```

L'enfant a reçu `SIGINT` et s'est arrêté. Pas irak : un shell ignore Ctrl-C pendant
qu'un enfant tourne, pour que seul l'enfant s'arrête.

Pour arrêter un processus qui n'est pas devant vous, trouvez son PID avec `ps`, puis
envoyez-lui un signal avec `kill`. Ouvrez un second terminal, lancez-y `sleep 1000`, et
depuis irak :

```
> ps -u ada -f
…
ada      48502 48499  0 09:47 pts/4    00:00:00 sleep 1000
> kill 48502
```

Dans l'autre terminal, le `sleep` se termine. Essayez d'abord `kill` tout court :
`SIGTERM` laisse au programme le temps de faire le ménage. N'utilisez `kill -9` que
lorsqu'un programme ignore `SIGTERM`.

### Résumé

- Un programme est un fichier. Un processus est un programme en cours d'exécution, avec
  un PID et un parent.
- Un processus a un répertoire courant, un environnement (`%*ENV`), trois flux standard
  (entrée 0, sortie 1, erreur 2), et laisse un statut de sortie (`$?`).
- Les commandes externes sont trouvées en cherchant dans les répertoires de `PATH`.
  `type` dit ce que signifie un nom.
- irak attend ses enfants. Les enfants héritent de copies de l'environnement et du
  répertoire courant, d'où le fait que `cd` soit intégré.
- Le code de sortie `0` signifie succès. Les signaux (`SIGINT`, `SIGTERM`, `SIGKILL`)
  arrêtent les processus.

### Exercices

1. Lancez `ls /` et vérifiez avec `$?` qu'il a réussi.
   <details><summary>Réponse</summary>

   ```
   > ls /
   bin  boot  dev  etc  home  …
   > $? == 0
   True
   ```
   </details>

2. Trouvez où se trouve le programme `git`. Si `git` n'est pas installé, essayez `cat`.
   <details><summary>Réponse</summary>

   `type git` affiche quelque chose comme `git is /usr/bin/git`.
   </details>

3. Expliquez pourquoi `printenv GREETING` n'affichait rien dans votre shell habituel
   après que vous avez défini `%*ENV.GREETING` dans irak et quitté irak.
   <details><summary>Réponse</summary>

   irak a modifié sa propre copie de l'environnement. Son parent, votre shell habituel,
   a sa propre copie, à laquelle irak ne peut pas toucher. Quand irak est sorti, sa copie
   a disparu avec lui.
   </details>

4. Lancez `sleep 5`, appuyez sur Ctrl-C, et affichez le numéro du signal qui l'a arrêté.
   <details><summary>Réponse</summary>

   `$?->signal` donne `2`, c'est-à-dire `SIGINT`.
   </details>

---

# Partie II : parler à irak

La partie I a montré irak comme un shell : un endroit où lancer des programmes. La
partie II montre irak comme un langage : des valeurs, des mots, des chaînes, et les
règles qui décident si un mot est du texte, une routine ou un programme à lancer.

## 4. Valeurs, mots et chaînes

### 4.1 Chaque soumission a une valeur

Chaque fois que vous soumettez une ligne, irak l'**évalue** : il détermine ce qu'elle
signifie et l'exécute. Le résultat est la **valeur** de la ligne, et irak l'affiche :

```
[0] > 2 + 2
4
[1] > 'hello'
hello
```

Une valeur est une donnée : un nombre, un morceau de texte, une liste, une date, un
chemin de fichier. Chaque valeur a un **type**, qui dit de quelle sorte de valeur il
s'agit. Vous pouvez demander son type à une valeur en écrivant `->WHAT` après elle :

```
[2] > 42->WHAT
(Int)
[3] > 'hello'->WHAT
(Str)
[4] > 2.5->WHAT
(Rat)
```

`Int` abrège *integer*, un entier, c'est-à-dire un nombre sans virgule. `Str` abrège
*string*, le mot des programmeurs pour un morceau de texte (une *chaîne* de caractères).
`Rat` abrège *rational number*, un nombre rationnel, une fraction ; nous y revenons plus
bas.

La flèche `->` pose une question à une valeur, ou lui demande de faire quelque chose. Le
mot après la flèche est une **méthode** : une chose que sait faire une valeur de ce
type. Les chaînes connaissent leur longueur, les nombres savent s'ils sont pairs :

```
[5] > 'hello'->chars
5
[6] > 'hello'->uc
HELLO
[7] > 'hello'->flip
olleh
[8] > 7->is-prime
True
```

Quand une méthode a besoin de plus d'informations, donnez-les entre parenthèses après
un point :

```
[9] > 'a-b-c'.split('-')
(a b c)
[10] > 'hello'.substr(1, 3)
ell
```

Donc : `->nom` appelle une méthode qui n'a besoin de rien de plus, et `.nom(…)` en
appelle une avec quelque chose entre les parenthèses. Retenez que le point seul, sans
parenthèses, signifie autre chose en rak ; le
[chapitre 9](#9-parcourir-les-structures-de-données) en parle.

### 4.2 Nombres

rak fait l'arithmétique comme vous l'avez apprise à l'école :

| Opérateur | Signifie | Exemple | Valeur |
|---|---|---|---|
| `+` | additionner | `3 + 4` | `7` |
| `-` | soustraire | `3 - 4` | `-1` |
| `*` | multiplier | `3 * 4` | `12` |
| `/` | diviser | `10 / 4` | `2.5` |
| `div` | diviser, partie entière seulement | `7 div 2` | `3` |
| `%` | reste d'une division | `7 % 2` | `1` |
| `**` | puissance | `2 ** 10` | `1024` |

La multiplication passe avant l'addition, et les parenthèses changent l'ordre :

```
> 3 + 2 * 4
11
> (3 + 2) * 4
20
```

Les entiers n'ont pas de limite de taille :

```
> 2 ** 100
1267650600228229401496703205376
```

La division donne une fraction exacte, un `Rat`, et non une approximation. C'est
pourquoi rak trouve le bon résultat d'une somme célèbre, sur laquelle beaucoup de
langages se trompent :

```
> 0.1 + 0.2 == 0.3
True
> 1 / 3
0.333333
```

irak n'affiche que quelques chiffres de `1 / 3`, mais il garde en interne la fraction
exacte.

Notez que rak, comme l'anglais, écrit les nombres décimaux avec un point : `2.5`, pas
`2,5`.

**Des espaces autour des opérateurs.** Écrivez toujours une espace de chaque côté d'un
opérateur : `3 + 4`, pas `3+4`. rak tient compte des espaces : au
[chapitre 11](#117-lespacement-fait-partie-de-la-syntaxe), `>fichier` écrit sans espace signifie « envoyer
ceci dans un fichier », tandis que `$a > $b`, espacé, compare deux nombres. Espacer tous
les opérateurs vous garde du bon côté.

**Écrivez `0.5`, pas `.5`.** En rak, un point suivi d'un nombre signifie « l'élément à
cette position » ([chapitre 9](#9-parcourir-les-structures-de-données)). `.5` est le sixième élément
de quelque chose, pas un demi. Écrivez le zéro.

### 4.3 Chaînes : nues et entre guillemets

Vous avez déjà tapé des chaînes sans guillemets : dans `say hello`, `hello` est une
chaîne. Un mot tapé sans guillemets que rak prend pour du texte est une **chaîne nue**
(*naked string*). La plupart des shells fonctionnent ainsi, et cela épargne beaucoup de
frappe :

```
> say hello
hello
> 'hello' eq hello
True
```

(`eq` compare deux chaînes ; voir [4.5](#45-vrai-faux-et-comparaisons).)

Un mot est une chaîne nue quand il commence par une lettre ou `_`, ne contient pas
d'espace, et n'est pas un mot que rak connaît déjà. « Connaît déjà » recouvre trois
cas :

1. Les **mots-clés**, les mots qui structurent le langage : `if`, `else`, `for`, `my`,
   `sub`, `return`, et quelques dizaines d'autres. Ils ne deviennent jamais des chaînes.
2. Les **routines et variables** que rak connaît à cet endroit : `say`, `uc`, les
   routines que vous écrivez vous-même ([4.4](#44-les-mots-qui-appellent-des-routines)).
3. Un mot **immédiatement suivi de `(`** : c'est toujours un appel.

Quand vous voulez un texte qu'une chaîne nue ne peut pas exprimer, utilisez des
guillemets :

- un texte avec des espaces : `'hello world'` ;
- un texte qui commence par un chiffre ou un symbole : `'42nd street'`, `'#hashtag'` ;
- un texte qui est aussi le nom d'une routine : `'say'`.

Il existe deux sortes de guillemets, qui diffèrent sur un point :

```
> my $name = 'Ada'
Ada
> say "hello $name"
hello Ada
> say 'hello $name'
hello $name
```

Les guillemets doubles **interpolent** : ils remplacent `$name` par la valeur qu'il
contient. Les guillemets simples (les apostrophes) gardent le texte exactement tel qu'il
est écrit. (`my $name = 'Ada'` crée une variable appelée `$name` et y met `Ada` ; le
[chapitre 7](#7-variables-et-sigils) traite des variables.) Les guillemets doubles
exécutent aussi tout code placé entre accolades :

```
> say "two and two make {2 + 2}"
two and two make 4
```

Deux chaînes se joignent avec `~`, espacé comme tout opérateur :

```
> 'rak' ~ ' ' ~ 'rocks'
rak rocks
```

Entre guillemets, quelques **séquences d'échappement** représentent des caractères
malcommodes à taper : `\n` pour un saut de ligne, `\t` pour une tabulation, `\"` pour un
guillemet double à l'intérieur de guillemets doubles. Elles ne fonctionnent qu'entre
guillemets doubles.

```
> say "one\ntwo"
one
two
```

### 4.4 Les mots qui appellent des routines

Une **routine** est un comportement nommé. `say`, `uc` (*upper case*, majuscules) et
`lc` (*lower case*, minuscules) sont des routines fournies par rak. Quand un mot nomme
une routine, les mots qui le suivent sont ses **arguments** : les valeurs sur lesquelles
elle travaille. Pas besoin de parenthèses :

```
> say uc hello
HELLO
```

Lisez de droite à gauche : `hello` est une chaîne nue ; `uc hello` appelle `uc` avec
elle, ce qui donne `HELLO` ; `say` affiche le résultat.

Vous pouvez écrire vos propres routines avec `sub` (pour *subroutine*, sous-programme) :

```
> sub double($x) { $x * 2 }
&double
> double 21
42
```

`sub double($x) { $x * 2 }` déclare une routine appelée `double` qui prend une valeur,
la nomme `$x`, et rend `$x * 2`. irak affiche `&double` : la routine elle-même est aussi
une valeur ([chapitre 10](#107-désigner-du-code)).

**La position compte.** rak lit votre texte de gauche à droite, et un mot ne devient un
appel de routine qu'une fois que rak a vu le `sub` de la routine. Avant cela, c'est une
chaîne nue :

```
> say triple; sub triple { 3 }
triple
> say triple
3
```

Sur la première ligne, `triple` est affiché comme du texte, car le `sub` vient plus loin
sur la ligne. Sur la seconde, `triple` est connu, donc il est appelé. Dans irak, où l'on
déclare en général une routine sur une ligne et l'utilise sur la suivante, cela compte
rarement. Dans un script, si : déclarez les routines avant de les appeler sans
parenthèses, ou appelez-les avec parenthèses, `triple()`, ce qui marche toujours.

### 4.5 Vrai, faux, et comparaisons

Les comparaisons donnent l'une de deux valeurs, `True` (vrai) ou `False` (faux). Les
nombres et les chaînes utilisent des opérateurs différents :

| Nombres | Chaînes | Signifie |
|---|---|---|
| `==` | `eq` | égal |
| `!=` | `ne` | différent |
| `<` | `lt` | inférieur (pour les chaînes : avant, dans l'ordre alphabétique) |
| `>` | `gt` | supérieur |
| `<=` | `le` | inférieur ou égal |
| `>=` | `ge` | supérieur ou égal |

```
> 3 == 3.0
True
> 'apple' lt 'banana'
True
> 10 < 9
False
```

Pourquoi deux jeux d'opérateurs ? Parce que `'10'` et `'9'` se comparent différemment
comme nombres et comme textes :

```
> '10' < '9'
False
> '10' lt '9'
True
```

Comme nombres, 10 est plus grand. Comme textes, `1` vient avant `9`, comme `apple` avant
`banana`. L'opérateur dit à rak quelle comparaison vous voulez.

`if` exécute un bloc de code seulement quand une condition est vraie. Un **bloc** est du
code entre accolades `{ }` :

```
> if 3 > 2 { say yes } else { say no }
yes
```

`and` (et), `or` (ou) et `not` (non) combinent des conditions :

```
> 3 > 2 and 'a' lt 'b'
True
> not 3 > 2
False
```

### 4.6 Plusieurs mots à la suite

Quand des mots suivent une routine, chaque mot est un argument distinct, comme dans un
shell. Voici une routine qui compte ses arguments (`*@a` les rassemble tous ; `->elems`
les compte) :

```
> sub count(*@a) { @a->elems }
&count
> count apples pears plums
3
```

Les virgules fonctionnent aussi, et se mélangent aux espaces :

```
> count apples, pears plums
3
> count (1 + 3) things
2
```

Le `(1 + 3)` entre parenthèses est calculé d'abord et passé comme un seul argument, `4`.

Cela explique aussi ce que vous avez vu au [chapitre 1](#13-votre-première-soumission) :
`say hello world` donne deux arguments à `say`, et `say` affiche ses arguments l'un
après l'autre, sans espace. Pour afficher une espace, elle doit faire partie d'une
chaîne : `say 'hello world'`, ou `say hello, ' ', world`.

### Résumé

- Chaque soumission a une valeur, et chaque valeur un type : `Int`, `Str`, `Rat`, …
- `->nom` appelle une méthode sans argument. `.nom(…)` en appelle une avec arguments.
- L'arithmétique est exacte. Espacez vos opérateurs. Écrivez `0.5`, pas `.5`.
- Une chaîne nue est un mot sans guillemets que rak ne connaît pas déjà. Mettez entre
  guillemets un texte avec espaces ou symboles. Les guillemets doubles interpolent
  `$nom` et `{code}` ; les simples, non.
- Un mot qui nomme une routine l'appelle ; les mots qui le suivent sont ses arguments.
- Les nombres se comparent avec `==` `<` `>`, les chaînes avec `eq` `lt` `gt`.

### Exercices

1. Que valent `17 div 5`, `17 % 5` et `17 / 5` ?
   <details><summary>Réponse</summary>

   `3`, `2` et `3.4`.
   </details>

2. Affichez `I am 36 years old` à l'aide d'une variable `$age` contenant `36`.
   <details><summary>Réponse</summary>

   ```
   > my $age = 36
   36
   > say "I am $age years old"
   I am 36 years old
   ```
   </details>

3. Écrivez une routine `shout` qui met son argument en majuscules et ajoute `!`. Puis
   appelez-la avec la chaîne nue `hey`.
   <details><summary>Réponse</summary>

   ```
   > sub shout($s) { uc($s) ~ '!' }
   &shout
   > shout hey
   HEY!
   ```
   </details>

4. Pourquoi `'Zebra' lt 'apple'` donne-t-il `True` ?
   <details><summary>Réponse</summary>

   Les chaînes se comparent caractère par caractère, selon leur code dans la table des
   caractères, où toutes les majuscules viennent avant toutes les minuscules. `Z` vient
   avant `a`. Comparez `'Zebra'->lc lt 'apple'` pour ignorer la casse.
   </details>

---

## 5. Commandes

### 5.1 Des lignes qui lancent des programmes

Le [chapitre 3](#3-processus) a montré irak lançant des programmes externes : `ls`,
`sleep`, `ps`. Le [chapitre 4](#4-valeurs-mots-et-chaînes) a montré irak calculant des
valeurs : `2 + 2`, `uc hello`. Pour irak, c'est la même chose : une **commande**. Une
commande est une ligne dont le premier mot nomme quelque chose à exécuter, suivi de ses
arguments :

```
> echo hello world
hello world
> say hello world
helloworld
```

`echo` est une commande externe, un programme sur disque, trouvé grâce à `PATH`. Il
affiche ses arguments séparés par des espaces. `say` est une routine rak, exécutée dans
irak sans nouveau processus. Sur la ligne, les deux se ressemblent, et irak les traite de
la même façon : le premier mot choisit ce qui s'exécute, et les mots suivants sont ses
arguments.

Un mot seul sur une ligne lance aussi une commande, si ce mot nomme un programme présent
dans `PATH` :

```
> ls
a  in.txt
> date
Fri Nov 20 10:14:02 CET 2026
```

Cela ne vaut que pour un mot seul sur sa ligne. Ailleurs, `ls` est une chaîne nue :

```
> my $x = ls
ls
```

### 5.2 Arguments

Les arguments sont séparés par des espaces, comme dans tout shell. Les guillemets
regroupent des mots contenant des espaces en un seul argument :

```
> touch 'my file.txt'
> ls -l 'my file.txt'
-rw-r--r-- 1 ada ada 0 Nov 20 10:15 my file.txt
```

Les variables sont remplacées par leur valeur, et restent un seul argument même quand la
valeur contient des espaces :

```
> my $f = 'my file.txt'
my file.txt
> ls $f
my file.txt
```

Une variable liste donne un argument par élément (les listes sont le sujet du
[chapitre 8](#8-structures-de-données-complexes)) :

```
> my @files = 'a.txt', 'b.txt'
[a.txt b.txt]
> touch @files
> ls @files
a.txt  b.txt
```

Le code entre accolades s'exécute, et sa valeur devient un argument :

```
> echo {6 * 7} answers
42 answers
```

Un mot qui commence par `/` est un chemin, même quand il a l'air bizarre : `ls /usr/bin`,
`cat /etc/hostname`. Un mot qui commence par `m/` est un motif (une *regex*, que ce
tutoriel ne couvre pas) ; un chemin relatif dont le premier répertoire est `m` s'écrit
donc `./m/…`.

Les options ne sont que des arguments qui commencent par `-`. Chaque programme décide
du sens de ses options, et les documente dans sa **page de manuel**, que `man` affiche :

```
> man ls
```

(`q` quitte `man`, comme il quitte `less`.)

### 5.3 Qui l'emporte pour un nom

Un nom peut signifier plusieurs choses à la fois. `sort` est une routine rak *et* un
programme dans `/usr/bin`. `type` liste toutes les significations, dans l'ordre :

```
> type sort
sort is a rak routine
sort is /usr/bin/sort
```

La première ligne est celle qui l'emporte. La règle : **les noms rak l'emportent sur les
commandes externes**. Vos propres routines, les routines de rak et les commandes
intégrées d'irak passent toutes avant n'importe quel programme de `PATH`.

Pour obtenir quand même le programme externe, mettez `^` devant son nom :

```
> ^sort names.txt
```

`^sort` exécute toujours `/usr/bin/sort`, quel que soit le sens de `sort` pour rak.

`type` renseigne aussi sur les commandes intégrées et sur vos propres routines :

```
> type cd
cd is a shell builtin
> sub greet { say hi }
&greet
> type greet
greet is a rak routine
```

### 5.4 Utiliser la sortie d'une commande comme valeur

En début de ligne, une commande externe écrit directement dans votre terminal. Quand
vous utilisez plutôt son résultat, comme partie de quelque chose de plus grand, irak
capture ce qu'elle aurait affiché et vous le donne sous forme de chaîne. Mettez la
commande entre parenthèses :

```
> my $listing = (ls)
a.txt
b.txt
my file.txt
> $listing->lines->elems
3
```

`->lines` découpe une chaîne en lignes, et `->elems` les compte : il y a trois fichiers.
La même idée, d'un seul trait :

```
> (ls)->lines->elems
3
```

Un `~` devant les parenthèses demande explicitement la chaîne :

```
> say "I am in " ~ ~(pwd)
I am in /home/ada/irak-tutorial
```

(La sortie capturée se termine par un saut de ligne, puisque `pwd` en a affiché un.
`->trim` retire espaces et sauts de ligne aux deux extrémités quand ils gênent.)

### 5.5 Le statut de sortie, en pratique

Le [chapitre 3](#35-comment-un-processus-se-termine) a présenté les statuts de sortie. irak affiche
une ligne grisée `exit N` après toute commande externe qui échoue, et garde le statut
dans `$?` :

```
> grep zebra a.txt
exit 1
> $? == 0
False
> $?->exitcode
1
```

`grep` cherche un mot dans des fichiers. Comme beaucoup de programmes, il se sert de son
code de sortie pour répondre à une question : `0` pour « trouvé », `1` pour « pas
trouvé », `2` pour « quelque chose s'est mal passé ». Vous pouvez donc l'utiliser dans
un `if` :

```
> grep -q hello notes.txt; if $? == 0 { say found } else { say 'not found' }
found
```

(`-q` rend `grep` silencieux : il n'affiche rien et se contente de fixer son statut de
sortie. Le `;` sépare deux instructions sur une même ligne.)

Une routine rak exécutée comme commande ne modifie pas `$?` ; seules les commandes
externes le font.

### 5.6 Redirections de commandes

> [!CAUTION]
> 🔴 **Ne se comporte pas (encore) comme décrit.** Rediriger une *commande externe*
> (`ls >listing.txt`, `^sort <fruit.txt`, `ls nothing 2>err.txt`) s'arrête actuellement
> sur une erreur comme `Type check failed in assignment to $out`. Rediriger des
> instructions rak, comme au [chapitre 11](#11-redirection-et-formats), fonctionne.

Toute commande externe a les trois flux standard du
[chapitre 3](#32-ce-que-porte-chaque-processus). Par défaut, tous trois sont branchés sur
votre terminal. Une **redirection** branche l'un d'eux sur un fichier à la place. Elle
s'écrit comme une flèche *collée* au nom du fichier :

| Écrit | Effet |
|---|---|
| `cmd >fichier` | la sortie standard va dans `fichier`, vidé au préalable |
| `cmd >>fichier` | la sortie standard est ajoutée à la fin de `fichier` |
| `cmd <fichier` | l'entrée standard est lue depuis `fichier` |
| `cmd 2>fichier` | l'erreur standard va dans `fichier` |
| `cmd 2>&1` | l'erreur standard va là où va la sortie standard |

```
> ls >listing.txt
> cat listing.txt
a.txt
b.txt
listing.txt
my file.txt
> date >>listing.txt
> date >>listing.txt
> cat listing.txt
a.txt
b.txt
listing.txt
my file.txt
Fri Nov 20 10:21:40 CET 2026
Fri Nov 20 10:21:43 CET 2026
```

`listing.txt` apparaît lui-même dans la liste : irak a créé le fichier avant de lancer
`ls`.

L'erreur standard est séparée de la sortie standard pour une raison : que les messages
d'erreur restent visibles quand les résultats partent dans un fichier.

```
> ls a.txt nothing >out.txt
ls: cannot access 'nothing': No such file or directory
exit 2
> cat out.txt
a.txt
```

Le résultat est allé dans le fichier, l'erreur est venue à l'écran. Envoyez maintenant
les erreurs dans leur propre fichier :

```
> ls a.txt nothing >out.txt 2>err.txt
exit 2
> cat err.txt
ls: cannot access 'nothing': No such file or directory
```

Et pour tout garder ensemble, envoyez les erreurs là où va la sortie. L'ordre compte :
d'abord la sortie vers le fichier, puis les erreurs vers là où va désormais la sortie :

```
> ls a.txt nothing >all.txt 2>&1
exit 2
> cat all.txt
ls: cannot access 'nothing': No such file or directory
a.txt
```

La redirection d'entrée fournit un fichier à un programme qui lit son entrée standard.
`sort` (le programme externe) trie les lignes qu'il lit :

```
> printf "pear\napple\nplum\n" >fruit.txt
> ^sort <fruit.txt
apple
pear
plum
```

**La flèche doit toucher le nom du fichier.** `>out.txt` est une redirection.
`> out.txt`, avec une espace, est la comparaison « supérieur à » du
[chapitre 4](#45-vrai-faux-et-comparaisons), qui n'a pas de sens après une commande ;
irak la refuse donc et vous dit comment corriger :

```
> ls > out.txt
===SORRY!=== Error while compiling
A redirection is written touching its target: use >target
```

Les mêmes flèches fonctionnent aussi sur des instructions rak, pas seulement sur des
commandes externes, et sur des valeurs rak, pas seulement sur du texte. Le
[chapitre 11](#11-redirection-et-formats) montre ce que cela apporte.

### Résumé

- Une commande est une ligne dont le premier mot nomme ce qu'il faut exécuter : une
  routine rak, une commande intégrée, ou un programme externe. Un mot seul qui nomme un
  programme de `PATH` le lance.
- Les arguments sont séparés par des espaces. Les guillemets regroupent. `$var` donne un
  argument, `@liste` un par élément, `{code}` sa valeur.
- Les noms rak l'emportent sur les programmes. `type nom` liste toutes les
  significations, la gagnante d'abord. `^nom` force le programme.
- `(cmd)` capture la sortie d'une commande sous forme de chaîne.
- `$?` contient le dernier statut de sortie ; irak affiche `exit N` en cas d'échec.
- `>fichier`, `>>fichier`, `<fichier`, `2>fichier`, `2>&1` redirigent les flux. La
  flèche touche le nom.

### Exercices

1. Enregistrez la liste des fichiers de `/usr/bin` dans `bin.txt`, puis comptez-les avec
   rak.
   <details><summary>Réponse</summary>

   ```
   > ls /usr/bin >bin.txt
   > (cat bin.txt)->lines->elems
   2417
   ```
   Votre nombre sera différent. `(ls /usr/bin)->lines->elems` donne le même compte sans
   fichier.
   </details>

2. Qu'affiche `type echo` sur votre machine ? Quel `echo` s'exécute quand vous tapez
   `echo hi` ?
   <details><summary>Réponse</summary>

   Quelque chose comme `echo is /usr/bin/echo`. Si rak ne définit pas d'`echo`, c'est ce
   programme qui s'exécute. Si un jour vous écrivez `sub echo { … }`, `type echo` liste
   votre routine en premier, et elle l'emporte ; `^echo hi` lancerait toujours le
   programme.
   </details>

3. Lancez `ls nothing` en envoyant le message d'erreur dans `oops.txt`. Quelque chose
   s'affiche-t-il à l'écran ?
   <details><summary>Réponse</summary>

   ```
   > ls nothing 2>oops.txt
   exit 2
   ```
   Seulement la note `exit 2` d'irak. Le message lui-même est dans `oops.txt`.
   </details>

4. Pourquoi `my $x = ls` ne liste-t-il pas de fichiers ?
   <details><summary>Réponse</summary>

   Un mot ne lance un programme que lorsqu'il est une commande : le premier mot d'une
   ligne. Après `my $x =`, `ls` est une chaîne nue. Écrivez `my $x = (ls)` pour capturer
   la liste.
   </details>

---

## 6. Le topique et l'historique

### 6.1 Le topique : chaque réponse nourrit la suivante

Une conversation s'appuie sur ce qui vient d'être dit. irak fait de même : la valeur de
chaque soumission est gardée dans une variable spéciale appelée `$_`, le **topique**
(*topic*, le sujet dont on parle), et la soumission suivante peut s'en servir.

```
[0] > 6 * 7
42
[1] > $_ + 1
43
[2] > $_ * 2
86
```

La ligne 1 a utilisé le 42 de la ligne 0. La ligne 2 a utilisé le 43 de la ligne 1. Le
topique sert aussi quand vous appelez une méthode sans rien devant la flèche :

```
[3] > 'irak'
irak
[4] > ->uc
IRAK
[5] > ->chars
4
```

`->uc` seul signifie « `->uc` appliqué au topique ». C'est ainsi qu'on explore quelque
chose pas à pas : produire une valeur, la regarder, faire le pas suivant à partir de là.
Vous vous en servirez beaucoup pour parcourir des données au
[chapitre 9](#93-partir-du-topique).

Le nom `$_` se prononce « le topique », ou « dollar souligné ». On l'appelle le topique
parce que, comme dans une conversation, c'est ce dont vous parlez en ce moment.

### 6.2 Ce qui ne touche pas au topique

Toutes les soumissions n'ont pas une valeur qui mérite d'être gardée. Trois sortes
laissent `$_` tel quel :

1. **Une soumission qui échoue.** Une faute de frappe n'efface pas votre travail.
2. **Une soumission dont la valeur est `Nil`**, la valeur « rien ici » de rak.
3. **Une soumission qui affiche quelque chose.** `say`, ou une commande externe qui
   écrit dans le terminal, vous a déjà montré son résultat ; sa valeur n'a pas
   d'intérêt.

```
[6] > 100
100
[7] > say 'just a remark'
just a remark
[8] > ls
a.txt  b.txt
[9] > 1 +
===SORRY!=== Error while compiling
Missing required term after infix
------> 1 +⏏<EOL>
[10] > $_
100
```

Le topique est toujours le `100` de la soumission 6. En pratique : afficher, lister des
fichiers et se tromper ne vous font jamais perdre la valeur sur laquelle vous
travailliez.

### 6.3 Rappeler des soumissions précédentes

irak numérote vos soumissions et se souvient des 1000 dernières. Quatre moyens en
rappellent une :

| Vous tapez | irak fait |
|---|---|
| ↑ et ↓ | avance ou recule dans les soumissions précédentes, une à la fois |
| `!n` puis ENTRÉE | exécute de nouveau la soumission numéro `n` |
| `!n` puis TAB | met le texte de la soumission `n` sur la ligne, pour que vous le modifiiez |
| `!!n` puis ENTRÉE | remet dans le topique `$_` la *valeur* de la soumission `n`, sans la réexécuter |

`!n` et `!!n` ne fonctionnent que lorsqu'ils forment toute la ligne.

```
[11] > 2 ** 16
65536
[12] > 'something else'
something else
[13] > !!11
65536
[14] > $_ - 1
65535
```

`!!11` a ramené la valeur de la soumission 11, pour que la soumission 14 puisse partir
de là. La différence entre `!11` et `!!11` compte quand la soumission a fait quelque
chose : `!11` le referait (recréer le fichier, retélécharger la page web), tandis que
`!!11` réutilise la valeur produite la première fois.

Les flèches s'arrêtent à la plus ancienne et à la plus récente soumission. Pour modifier
une longue soumission, rappelez-la avec `!n` TAB, modifiez-la, et appuyez sur ENTRÉE :
elle s'exécute comme une nouvelle soumission, avec un nouveau numéro.

### Résumé

- Le topique `$_` contient la valeur de la soumission précédente.
- Un `->méthode` en tête de ligne (et, au [chapitre 9](#93-partir-du-topique), un
  `.` en tête) agit sur le topique.
- Les échecs, `Nil` et les soumissions qui affichent laissent le topique inchangé.
- ↑ ↓, `!n` (réexécuter), `!n` TAB (modifier), `!!n` (réutiliser la valeur) rappellent
  des soumissions.

### Exercices

1. En partant de `'banana'`, utilisez le topique pour obtenir sa longueur, puis cette
   longueur doublée, en trois soumissions.
   <details><summary>Réponse</summary>

   ```
   > 'banana'
   banana
   > ->chars
   6
   > $_ * 2
   12
   ```
   </details>

2. Vous avez calculé une valeur à la soumission 3, puis lancé `ls` et `say hi`. Que
   vaut `$_` maintenant ?
   <details><summary>Réponse</summary>

   Toujours la valeur de la soumission 3 : `ls` et `say` ont affiché quelque chose, ils
   ont donc laissé le topique tranquille.
   </details>

3. La soumission 5 était `date >>log.txt`. Quelle différence entre taper `!5` et `!!5` ?
   <details><summary>Réponse</summary>

   `!5` réexécute `date >>log.txt` et ajoute une seconde ligne à `log.txt`. `!!5` met
   dans le topique la valeur qu'avait la soumission 5, et ne touche pas à `log.txt`.
   </details>

---

# Partie III : les données

Jusqu'ici, les valeurs étaient des choses isolées : un nombre, un mot. Les vraies données
viennent en collections : une liste de fichiers, une personne avec un nom et un âge, une
équipe de personnes ayant chacune ses projets. La partie III montre comment rak contient
de telles données, comment s'y retrouver à l'intérieur, et comment deux noms peuvent
désigner le même morceau de données.

## 7. Variables et sigils

### 7.1 Nommer une valeur

Le topique `$_` garde votre dernière valeur, mais seulement la dernière. Pour garder une
valeur plus longtemps, donnez-lui un nom. Un emplacement nommé qui contient une valeur
est une **variable** :

```
> my $city = 'Lyon'
Lyon
> say "I live in $city"
I live in Lyon
```

`my` **déclare** la variable : il dit à rak que désormais `$city` est un nom que vous
utilisez. `=` lui **affecte** une valeur : il y met `'Lyon'`. Vous pouvez affecter une
nouvelle valeur plus tard, sans `my` :

```
> $city = 'Nantes'
Nantes
> $city
Nantes
```

Déclarez une variable une fois, avec `my`, puis utilisez-la aussi souvent que vous
voulez. Utiliser une variable jamais déclarée est une erreur, ce qui vous protège des
fautes de frappe :

```
> say $ctiy
===SORRY!=== Error while compiling
Variable '$ctiy' is not declared.  Did you mean '$city'?
```

Un nom de variable commence par un symbole, ici `$`, suivi de lettres, de chiffres, de
`_` ou de `-` : `$city`, `$file-count`, `$max_size`, `$x2`. Évitez les lettres
accentuées dans les noms : elles sont permises, mais tous les claviers ne les tapent pas
facilement.

### 7.2 Les sigils : l'étiquette sur la boîte

Le symbole au début du nom d'une variable est son **sigil**. Imaginez une variable comme
une boîte qui porte un nom. Le sigil est un dessin sur l'étiquette, qui vous dit quelle
sorte de boîte c'est avant même de l'ouvrir.

rak a quatre sigils qu'il partage avec Raku, le langage sur lequel il est bâti :

| Sigil | Se lit | Contient | Exemple |
|---|---|---|---|
| `$` | « le » | **une seule chose** (un scalaire) | `$city`, `$count` |
| `@` | « ces » | **une liste ordonnée** de choses (un tableau) | `@files`, `@scores` |
| `%` | « cette table » | **des entrées nommées** : des clés et leurs valeurs (un hachage) | `%person`, `%*ENV` |
| `&` | « fais » | **un morceau de code** (une routine) | `&double`, `&say` |

Le `$` ressemble au S de *scalar* (scalaire, unique). Le `@` ressemble au a de *array*
(tableau). Le `%` montre deux petits cercles séparés d'une barre oblique, comme une clé
et sa valeur. Vous rencontrerez vraiment `@` et `%` au
[chapitre 8](#8-structures-de-données-complexes).

```
> my @fruit = 'apple', 'pear', 'plum'
[apple pear plum]
> my %person = name => 'Ada', age => 36
{age => 36, name => Ada}
```

Le sigil change aussi l'effet de l'affectation. Affecter plusieurs valeurs à une
variable `@` les garde toutes. Les affecter à une variable `$` les range comme une seule
chose, une liste unique ; le [chapitre 10](#105-des-boîtes-dans-des-boîtes--litémisation) explique
la différence.

Vous avez aussi vu des variables avec un second symbole après le sigil : `$*CWD`,
`%*ENV`, `$*PID`. Le `*` marque une **variable dynamique**, que rak fournit et qui
décrit la situation dans laquelle vous travaillez : le répertoire courant,
l'environnement, l'identifiant de processus. Vous les lisez comme n'importe quelle
variable.

### 7.3 Les sigils propres à rak : `~` et `#`

rak ajoute deux sigils à lui, pour les deux sortes de valeurs qu'on utilise le plus
souvent :

| Sigil | Contient | Par défaut | Exemple |
|---|---|---|---|
| `~` | un morceau de texte (une chaîne native) | `""` (vide) | `~name`, `~path` |
| `#` | un nombre entier (un entier natif) | `0` | `#count`, `#i` |

Le `~` rappelle le `~` qui joint les chaînes. Le `#` est le « signe dièse », le signe des
nombres en anglais.

```
> my ~greeting = 'hello'
hello
> my #count = 3
3
> #count = #count + 1
4
> say "~greeting, I counted #count"
hello, I counted 4
```

Ils s'interpolent entre guillemets doubles comme les variables `$`.

Que veut dire **natif** ? Une variable `$` est une boîte qui peut contenir n'importe
quoi : un nombre maintenant, une chaîne plus tard, une liste ensuite. Pour que ce soit
possible, rak garde en coulisse un petit conteneur qui pointe vers la valeur. Chaque
lecture suit le pointeur, et chaque nouveau nombre est un nouvel objet en mémoire. C'est
souple, et lent quand on le répète un million de fois.

Une variable `~` ou `#` contient directement la valeur brute, comme le processeur
lui-même stocke textes et nombres. Pas de conteneur à suivre, rien de plus à créer. Elles
sont donc plus rapides, et elles sont strictes :

```
> my #n = 2.7
===SORRY!=== Error while compiling
Cannot assign a literal of type Rat (2.7) to a native variable (#n) of type int.
> my #n = 'abc'
This type cannot unbox to a native integer: P6opaque, Str
```

Une variable `#` contient des nombres entiers, et rien d'autre. Une variable `~` contient
du texte, et rien d'autre. Le sigil *est* le type, on ne peut donc pas lui ajouter un
autre type : `my Str ~s` est une erreur.

Leur autre raison d'être, celle pour laquelle on les a ajoutées, est de rendre court le
parcours des données. Vous verrez pourquoi au [chapitre 9](#94-des-pas-contenus-dans-des-variables).

### 7.4 Choisir un sigil

| Vous voulez garder… | Utilisez |
|---|---|
| un mot, un nom, une ligne de texte | `~` |
| un compte, une position, un indice | `#` |
| une fraction, une date, un chemin, ou « n'importe quoi » | `$` |
| une valeur qui peut manquer (indéfinie) | `$` |
| plusieurs valeurs dans un ordre | `@` |
| des valeurs retrouvées par leur nom | `%` |
| une routine, pour la transmettre | `&` |

Dans le doute, `$` marche toujours. Utilisez `~` et `#` quand vous savez que la valeur
est du texte ou un entier, ce qui est le cas la plupart du temps.

### 7.5 Valeurs manquantes

Une variable `$` déclarée sans valeur est **indéfinie** : la boîte est vide.

```
> my $later
(Any)
> $later->defined
False
```

`(Any)` est la façon dont irak montre une boîte `$` vide. `->defined` demande s'il y a
une valeur. L'opérateur `//` (« défini-ou ») donne une valeur de remplacement quand il
n'y en a pas :

```
> $later // 'nothing yet'
nothing yet
> $later = 5
5
> $later // 'nothing yet'
5
```

Vous utiliserez beaucoup `//` quand les données peuvent être incomplètes
([9.9](#99-chemins-manquants)).

Une valeur voisine est `Nil`, qui signifie « pas de valeur ici ». Une routine qui ne
trouve rien renvoie `Nil`, et affecter `Nil` à une variable `$` la vide.

Les variables `~` et `#` ne sont jamais indéfinies. Sans valeur, elles contiennent leur
valeur par défaut :

```
> my ~empty
> my #zero
0
```

(`my ~empty` affiche une ligne vide : la chaîne vide.) Les listes et hachages vides
s'affichent `[]` et `{}`.

### 7.6 Types et commentaires

La valeur de chaque variable a un type, et `->WHAT` le montre :

```
> $city->WHAT
(Str)
> @fruit->WHAT
(Array)
> %person->WHAT
(Hash)
> $*CWD->WHAT
(Path)
```

Un mot sur `#`. Avant rak, `#` ne servait qu'à commencer les commentaires. C'est toujours
le cas, pourvu qu'une espace ou un symbole le suive :

```
> 1 + 1   # ceci est un commentaire
2
> say #count    # ceci est la variable #count, puis un commentaire
4
```

`#count`, avec une lettre juste après le `#`, est la variable. Pour commencer un
commentaire, mettez une espace après le `#`. Un `#oups` non déclaré est une erreur : une
espace oubliée se remarque donc tout de suite.

### 7.7 Portée : là où un nom est valide

Un **bloc**, du code entre accolades `{ }`, est un petit monde à part. Une variable
déclarée dans un bloc n'existe qu'à l'intérieur :

```
> my $y = 3
3
> { my $y = 4; say $y }
4
> $y
3
```

Le `$y` intérieur est une autre variable, qui cache celle de l'extérieur jusqu'à la fin
du bloc. La partie du code où un nom est valide est sa **portée** (*scope*). Dans irak,
chaque soumission voit les variables déclarées au niveau supérieur par les précédentes.

### Résumé

- `my` déclare une variable. `=` affecte une valeur.
- Le sigil dit quelle sorte de boîte : `$` une chose, `@` une liste, `%` des entrées
  nommées, `&` du code. Un `*` après le sigil marque une variable fournie par rak
  (`$*CWD`, `%*ENV`).
- Les sigils `~` (texte) et `#` (entier) de rak sont natifs : rapides, stricts, jamais
  indéfinis.
- `->defined` et `//` traitent les valeurs manquantes.
- `#nom` est une variable ; `# ` avec une espace commence un commentaire.
- Une variable déclarée dans un bloc n'existe que dans ce bloc.

### Exercices

1. Déclarez `#width` valant 12 et `#height` valant 5, et affichez `area: 60` en les
   utilisant.
   <details><summary>Réponse</summary>

   ```
   > my #width = 12
   12
   > my #height = 5
   5
   > say "area: {#width * #height}"
   area: 60
   ```
   </details>

2. Quel sigil utiliseriez-vous pour : un nom de fichier ; le nombre de lignes d'un
   fichier ; le prix d'un café ; la liste de vos amis ; les numéros de téléphone de vos
   amis ?
   <details><summary>Réponse</summary>

   `~` pour le nom de fichier, `#` pour le nombre de lignes, `$` pour le prix (il a une
   partie décimale), `@` pour la liste des amis, `%` pour les numéros, retrouvés par
   nom.
   </details>

3. Qu'affiche `my $x; say $x // 'empty'` ? Et `my #x; say #x // 'empty'` ?
   <details><summary>Réponse</summary>

   `empty`, puis `0` : `#x` n'est jamais indéfini, donc `//` garde sa valeur.
   </details>

---

## 8. Structures de données complexes

### 8.1 Tableaux

Un **tableau** (*array*) est une liste ordonnée de valeurs. Écrivez les valeurs
séparées par des virgules :

```
> my @scores = 12, 7, 30
[12 7 30]
```

Les valeurs sont des **éléments**. Chacun a une **position**, aussi appelée son
**indice**, comptée à partir de **0** : `12` est à la position 0, `7` à la 1, `30` à la
2. Compter à partir de zéro semble bizarre au début ; voyez l'indice comme « combien de
pas depuis le début ».

Les tableaux savent des choses sur eux-mêmes :

```
> @scores->elems        # combien d'éléments
3
> @scores->end          # le dernier indice
2
> @scores->sum
49
> @scores->sort
(7 12 30)
> @scores->max
30
```

Ils peuvent grandir et rétrécir par la fin :

```
> @scores.push(25)
[12 7 30 25]
> @scores->pop
25
> @scores
[12 7 30]
```

`push` ajoute un élément à la fin (il doit savoir *quoi* ajouter, il prend donc des
parenthèses). `pop` retire le dernier élément et le rend. `unshift` et `shift` font de
même au début.

Pour une liste de mots, `<…>` épargne virgules et guillemets :

```
> my @days = <mon tue wed thu fri>
[mon tue wed thu fri]
```

Les crochets font aussi un tableau, comme valeur à part entière, sans variable :

```
> [1, 2, 3]->elems
3
```

### 8.2 Hachages

Un **hachage** (*hash*) est une table de **clés** et de **valeurs**. Chaque clé est un
nom, et mène à une valeur. Écrivez chaque entrée sous la forme `clé => valeur` :

```
> my %phone = Ada => '555-0101', Bo => '555-0123'
{Ada => 555-0101, Bo => 555-0123}
```

Un hachage n'a pas d'ordre propre. irak montre ses clés par ordre alphabétique, pour
qu'on les trouve facilement, mais rak peut vous les donner dans n'importe quel ordre.
Quand l'ordre compte, triez les clés :

```
> %phone->keys->sort
(Ada Bo)
> %phone->values
(555-0101 555-0123)
> %phone->elems
2
```

Chaque clé apparaît une seule fois. Affecter à une clé existante remplace sa valeur ;
affecter à une nouvelle clé ajoute une entrée :

```
> %phone.Cy = '555-0199'
555-0199
> %phone->elems
3
```

(`%phone.Cy` signifie « l'entrée `Cy` de `%phone` » ; le
[chapitre 9](#9-parcourir-les-structures-de-données) est consacré à ce point.)

Les accolades font un hachage comme valeur à part entière :

```
> { a => 1, b => 2 }->keys->sort
(a b)
```

### 8.3 Imbrication

Voici la partie puissante : un élément de tableau, ou une valeur de hachage, peut
lui-même être un tableau ou un hachage. Les données qui collent au monde réel sont en
général **imbriquées** :

- une personne est un hachage : nom, âge, rôle ;
- les projets d'une personne sont un tableau de hachages : chaque projet a un nom et des
  étiquettes (*tags*) ;
- les étiquettes d'un projet sont un tableau de chaînes ;
- une équipe est un hachage avec un nom et un tableau de personnes.

Dessinez-le comme un arbre, à la manière de l'arbre des fichiers du
[chapitre 2](#21-larbre) :

```
team (hachage)
├── name: "Orbit"
└── people (tableau)
    ├── 0 (hachage)
    │   ├── name: "Ada"
    │   ├── age: 36
    │   ├── role: "lead"
    │   └── projects (tableau)
    │       ├── 0 (hachage)
    │       │   ├── name: "rak"
    │       │   ├── stars: 120
    │       │   └── tags (tableau): "lang", "shell"
    │       └── 1 (hachage)
    │           ├── name: "irak"
    │           ├── stars: 45
    │           └── tags (tableau): "repl", "shell"
    ├── 1 (hachage)
    │   ├── name: "Bo"  …
    └── 2 (hachage)
        ├── name: "Cy"  …
```

Des clés dans les hachages, des positions dans les tableaux : chaque pas vers le bas de
l'arbre est soit un nom, soit un nombre. Gardez cette image en tête ; le chapitre suivant
explique comment s'y déplacer.

### 8.4 Construire `team.json`

Tapez ceci dans irak. C'est long, mais irak attend tant qu'un crochet est ouvert ; vous
pouvez donc l'étaler sur plusieurs lignes, comme montré. L'invite de continuation `...`
apparaît d'elle-même.

```
> my %team =
...     name   => 'Orbit',
...     people => [
...         { name => 'Ada', age => 36, role => 'lead',
...           projects => [ { name => 'rak',  tags => ['lang', 'shell'], stars => 120 },
...                         { name => 'irak', tags => ['repl', 'shell'], stars => 45 } ] },
...         { name => 'Bo', age => 29, role => 'dev', manager => 'Ada',
...           projects => [ { name => 'myaml', tags => ['data', 'yaml'], stars => 12 }, ] },
...         { name => 'Cy', age => 41, role => 'ops', manager => 'Ada', projects => [] },
...     ];
```

irak affiche le résultat sur une longue ligne. Avant de la lire, deux détails de ce que
vous avez tapé.

**La virgule finale dans les projets de Bo.** Regardez `[ { name => 'myaml', … }, ]`. La
virgule avant `]` n'est pas une faute de frappe. Quand des crochets contiennent une seule
chose et aucune virgule, rak *ouvre* cette chose et met son contenu dans le tableau : un
hachage seul devient la liste de ses entrées, et vous obtenez un tableau de paires
clé-valeur au lieu d'un tableau contenant un hachage. La virgule dit « ceci est une liste
d'un élément ». La règle : **un tableau contenant un seul hachage a besoin d'une virgule
finale.** Les projets d'Ada comptent deux hachages séparés par une virgule, ils n'en ont
donc pas besoin. Les projets de Cy sont `[]`, vides.

**Les listes de mots entre crochets.** `<lang shell>` serait plus court que
`['lang', 'shell']`, mais rak n'accepte pas les listes de mots `<…>` entre crochets.
Utilisez-y des guillemets.

### 8.5 Lire l'affichage d'irak

irak montre `%team` ainsi (replié ici pour tenir dans la page) :

```
{name => Orbit, people => [{age => 36, name => Ada, projects => [{name => rak,
stars => 120, tags => [lang shell]} {name => irak, stars => 45, tags => [repl
shell]}], role => lead} {age => 29, manager => Ada, name => Bo, projects =>
[{name => myaml, stars => 12, tags => [data yaml]}], role => dev} {age => 41,
manager => Ada, name => Cy, projects => [], role => ops}]}
```

Pour le lire, appariez les crochets : `{ }` autour d'un hachage, `[ ]` autour d'un
tableau. Dans un hachage, `clé => valeur` ; dans un tableau, les éléments, séparés par
des espaces. Les chaînes sont montrées sans guillemets.

C'est difficile à lire dès que c'est plus gros. Enregistrer les données en JSON
([8.6](#86-enregistrer-et-charger--un-avant-goût)) et regarder le fichier donne une image bien plus
claire, une valeur par ligne, indentée selon la profondeur. Le
[chapitre suivant](#9-parcourir-les-structures-de-données) montre comment regarder une partie à la
fois, ce que vous ferez le plus souvent.

### 8.6 Enregistrer et charger : un avant-goût

Enregistrez l'équipe dans un fichier :

```
> %team >team.json
> cat team.json
{
  "name": "Orbit",
  "people": [
    {
      "age": 36,
      "name": "Ada",
      "projects": [
        {
          "name": "rak",
          "stars": 120,
          "tags": [
            "lang",
            "shell"
          ]
        },
…
```

`>team.json` envoie la valeur de `%team` dans le fichier `team.json`. Comme le nom se
termine par `.json`, rak écrit la valeur au format **JSON**. Rechargez-la, dans une
nouvelle variable :

```
> my %copy <team.json
> %copy.people.1.name
Bo
```

`<team.json` lit le fichier et le décode en hachages et tableaux. Vous avez maintenant un
fichier de données pour expérimenter : si vous abîmez `%team`, rechargez-le. Désormais, le
tutoriel suppose que `%team` est chargé :

```
> my %team <team.json
```

Le [chapitre 11](#11-redirection-et-formats) explique `>` et `<` en détail.

### 8.7 JSON, la langue commune des données

**JSON** (*JavaScript Object Notation*, prononcé « djé-sonne ») est un format texte pour
les données imbriquées. Presque tous les programmes, langages et services web savent le
lire et l'écrire, d'où le choix de rak d'en faire son premier format de données. Il
comprend :

| JSON | rak |
|---|---|
| `{ "clé": valeur, … }` (un objet) | un hachage |
| `[ valeur, … ]` (un tableau) | un tableau |
| `"texte"` | une chaîne |
| `42`, `3.14` | un nombre |
| `true`, `false` | `True`, `False` |
| `null` | une valeur indéfinie |

C'est tout. Certaines valeurs rak n'ont pas de forme JSON : un ensemble, l'infini
(`Inf`), une date, une routine. En enregistrer une échoue avec une erreur qui nomme le
coupable, et laisse le fichier intact ([11.6](#116-quand-un-format-échoue)). Transformez
d'abord ces valeurs en chaînes ou en nombres.

### Résumé

- Un tableau (`@`) est une liste ordonnée. Les positions comptent à partir de 0.
  `->elems`, `.push(…)`, `->pop`, `->sort`, `->sum`.
- Un hachage (`%`) associe des clés à des valeurs. Il n'a pas d'ordre ; triez ses clés
  quand l'ordre compte.
- Tableaux et hachages s'imbriquent. Dessinez l'arbre : chaque pas vers le bas est une
  clé ou une position.
- `[ { … }, ]` : un hachage seul entre crochets a besoin d'une virgule finale.
- `%team >team.json` enregistre en JSON ; `my %team <team.json` charge.

### Exercices

1. Faites un tableau des cinq premiers carrés (1, 4, 9, 16, 25), puis calculez leur
   somme et leur plus grande valeur.
   <details><summary>Réponse</summary>

   ```
   > my @sq = 1, 4, 9, 16, 25
   [1 4 9 16 25]
   > @sq->sum
   55
   > @sq->max
   25
   ```
   </details>

2. Faites un hachage `%capital` associant trois pays à leur capitale, et ajoutez-en un
   quatrième.
   <details><summary>Réponse</summary>

   ```
   > my %capital = France => 'Paris', Japan => 'Tokyo', Peru => 'Lima'
   {France => Paris, Japan => Tokyo, Peru => Lima}
   > %capital.Kenya = 'Nairobi'
   Nairobi
   ```
   </details>

3. Qu'est-ce qui cloche dans `my @a = [ { x => 1, y => 2 } ]` ? Vérifiez avec
   `@a->elems`.
   <details><summary>Réponse</summary>

   Sans virgule finale, le hachage seul est ouvert : `@a` contient deux paires,
   `x => 1` et `y => 2`, donc `@a->elems` vaut 2. Avec `[ { x => 1, y => 2 }, ]`, il
   contient un hachage, et `->elems` vaut 1.
   </details>

4. Dessinez l'arbre de `{ title => 'Notes', pages => [ { n => 1 }, { n => 2 } ] }`.
   <details><summary>Réponse</summary>

   ```
   (hachage)
   ├── title: "Notes"
   └── pages (tableau)
       ├── 0 (hachage)
       │   └── n: 1
       └── 1 (hachage)
           └── n: 2
   ```
   </details>

---

## 9. Parcourir les structures de données

### 9.1 Un pas à la fois

Pour atteindre l'intérieur d'un hachage ou d'un tableau, écrivez un point suivi du pas :
une clé pour un hachage, une position pour un tableau. C'est un **indice pointé**
(*dotty subscript*). (« Indice » est le mot des programmeurs pour « ce qui dit quel
élément ».)

```
> %team.name
Orbit
> %team.people
[{age => 36, …} {age => 29, …} {age => 41, …}]
> my @people = %team.people->list
> @people.0
{age => 36, name => Ada, projects => [...], role => lead}
```

(Les valeurs longues sont abrégées avec `…` dans ce tutoriel. Le `->list` fait que
`@people` contient les trois personnes, plutôt qu'un seul tableau de trois personnes ;
[9.6](#96-visiter-chaque-élément) en dit plus.)

`%team.name` est la valeur sous la clé `name`. `@people.0` est l'élément à la position
0. Un pas qui est un mot est une clé ; un pas qui est un nombre est une position.

Quand une clé n'est pas un simple mot, mettez-la entre guillemets :

```
> my %odd = 'first name' => 'Ada', '2024' => 'leap'
{2024 => leap, first name => Ada}
> %odd.'first name'
Ada
> %odd.'2024'
leap
```

Sans les guillemets, `%odd.2024` demanderait la *position* 2024, or `%odd` est un
hachage, pas un tableau : rak répond `Index out of range`. Les guillemets doubles
interpolent, donc une clé contenue dans une variable `$` marche aussi :

```
> my $which = 'first name'
first name
> %odd."$which"
Ada
```

### 9.2 Chemins

Les pas s'enchaînent. Chacun part de là où le précédent est arrivé :

```
> %team.people.0.name
Ada
> %team.people.0.projects.1.name
irak
> %team.people.0.projects.1.tags.0
repl
```

Lisez `%team.people.0.projects.1.tags.0` de gauche à droite, en suivant l'arbre de
[8.3](#83-imbrication) : partir de l'équipe ; prendre ses membres ; prendre la première
personne ; prendre ses projets ; prendre le deuxième projet ; prendre ses étiquettes ;
prendre la première étiquette. Une telle chaîne de pas est un **chemin**, exactement
comme `/home/ada/photos` est un chemin dans l'arbre des fichiers, avec `.` au lieu de `/`.

Si vous connaissez **jq**, un outil répandu pour le JSON, cela vous semblera familier :
jq écrit le même chemin `.people[0].projects[1].tags[0]`.

Les chemins servent aussi à modifier les données. Affectez à un chemin pour changer la
valeur à son extrémité :

```
> %team.people.0.age = 37
37
> %team.people.0.age
37
```

Affecter à une clé qui n'existe pas encore l'ajoute :

```
> %team.people.2.projects.0 = { name => 'deploy', stars => 3, tags => ['ops'] }
{name => deploy, stars => 3, tags => [ops]}
```

Cy a maintenant un projet. Pour annuler vos expériences, rechargez le fichier.
Faites-le maintenant, pour que la suite du chapitre montre les mêmes résultats que votre
écran :

```
> my %team <team.json
```

### 9.3 Partir du topique

Dans irak, on tape rarement un chemin entier d'un coup. On fait un pas, on regarde le
résultat, et on fait le pas suivant à partir de là. Un indice pointé sans rien devant
part du topique `$_`, la valeur de la soumission précédente
([chapitre 6](#6-le-topique-et-lhistorique)) :

```
[0] > %team
{name => Orbit, people => […]}
[1] > .people
[{…} {…} {…}]
[2] > .1
{age => 29, manager => Ada, name => Bo, projects => […], role => dev}
[3] > .projects
[{name => myaml, stars => 12, tags => [data yaml]}]
[4] > .0.tags
[data yaml]
[5] > ->elems
2
```

C'est explorer des données par la conversation : chaque réponse vous montre quelle peut
être la question suivante. Quand vous faites fausse route, `!!n`
([6.3](#63-rappeler-des-soumissions-précédentes)) ramène la valeur d'une étape précédente :

```
[6] > !!2
{age => 29, manager => Ada, name => Bo, projects => […], role => dev}
[7] > .age
29
```

Vous pouvez aussi charger un fichier directement dans le topique : `<team.json` seul,
sans rien à sa gauche, lit le fichier et en fait le topique.

```
[8] > <team.json
[9] > .people.2.role
ops
```

> **Voilà pourquoi `.5` n'est pas un demi.** Un point suivi d'un nombre est un indice sur
> le topique : `.5` est la position 5 de `$_`. Écrivez `0.5` pour le nombre.

### 9.4 Des pas contenus dans des variables

Souvent, le pas lui-même est dans une variable : vous bouclez sur des positions, ou
l'utilisateur a tapé une clé. Avec des variables `$`, vous écririez `."$key"`, avec des
guillemets, comme en 9.1. Avec les sigils propres à rak, c'est plus simple : un point
suivi d'une variable `~` utilise son texte comme clé, et un point suivi d'une variable
`#` utilise son nombre comme position.

```
> my ~field = 'role'
role
> my #who = 2
2
> %team.people.#who.~field
ops
```

C'est la principale raison d'être des sigils `~` et `#` : le sigil dit à rak, pendant
qu'il lit votre ligne, si un pas est une clé ou une position, sans crochets ni
guillemets.

Une variable `$` juste après le point est une erreur, car rak ne saurait pas de quelle
sorte de pas il s'agit :

```
> %team.$key
===SORRY!=== Error while compiling
In rak, '.$key' is not an indirect method call: use '->$key' to call it, or '."$key"' to subscript by it
```

### 9.5 Indices et méthodes

Vous avez maintenant vu trois choses qui suivent une valeur :

| Écrit | Signifie | Exemple |
|---|---|---|
| `.mot` | l'entrée nommée `mot` (un indice) | `%team.name` |
| `->mot` | demander à la valeur de faire `mot` (une méthode, sans arguments) | `%team->elems` |
| `.mot(…)` | demander à la valeur de faire `mot` avec des arguments | `@scores.push(25)` |

La différence entre les deux premiers compte dès qu'une clé et une méthode portent le
même nom. Un hachage sait donner ses clés (`keys`), mais il peut aussi *avoir* une entrée
appelée `keys` :

```
> my %h = keys => 'under the mat', door => 'red'
{door => red, keys => under the mat}
> %h.keys
under the mat
> %h->keys
(door keys)
```

`.keys` lit les données ; `->keys` interroge le hachage. La règle est simple : **un
point lit les données, une flèche interroge la valeur.** Des parenthèses vides appellent
aussi une méthode : `%h.keys()` équivaut à `%h->keys`.

Méthodes et indices s'enchaînent librement :

```
> %team.people.0.projects->elems
2
> %team.people->elems
3
> %team.people.0->keys->sort
(age name projects role)
```

### 9.6 Visiter chaque élément

Une **boucle** répète un bloc pour chaque élément d'une liste. `for` met tour à tour
chaque élément dans le topique `$_` ; le point, dans le bloc, lit donc l'élément
courant :

```
> for %team.people->list { say .name }
Ada
Bo
Cy
```

Pourquoi `->list` ? Parce que le tableau des personnes se trouve *dans* le hachage
`%team`, dans une boîte à lui, et `for` ferait sinon un seul tour, sur la boîte. `->list`
ouvre la boîte et donne les éléments. Le [chapitre 10](#105-des-boîtes-dans-des-boîtes--litémisation)
explique ces boîtes. Pour l'instant, retenez : **pour boucler sur un tableau pris à
l'intérieur d'une structure, ajoutez `->list`.** Une variable `@` n'en a pas besoin :
`for @people { say .name }` fonctionne.

Pour nommer l'élément au lieu d'utiliser le topique, écrivez `->` et une variable après
la liste. C'est un **bloc pointu** (*pointy block*) :

```
> for %team.people->list -> %person { say %person.name, ': ', %person.age }
Ada: 36
Bo: 29
Cy: 41
```

Un hachage se parcourt par ses clés, par ses valeurs, ou par les deux. `->kv` donne
alternativement clés et valeurs, et un bloc pointu peut en prendre deux à la fois :

```
> my %p = %team.people.1
> for %p->keys->sort -> ~k { say ~k }
age
manager
name
projects
role
> for %p->kv -> $k, $v { say "$k: $v" if $v ~~ Str }
role: dev
manager: Ada
name: Bo
```

Les lignes peuvent arriver dans un autre ordre sur votre écran : un hachage n'a pas
d'ordre propre.

(`$v ~~ Str` demande « `$v` est-il une chaîne ? » ; `~~` est l'opérateur de
**smartmatch** (correspondance intelligente), qui teste une valeur contre un type, un
motif ou une autre valeur.)

Les tableaux se parcourent aussi par position avec `->keys`, qui donne `0, 1, 2…` :

```
> for @people->keys -> #i { say "#i: {@people.#i.name}" }
0: Ada
1: Bo
2: Cy
```

### 9.7 Transformer des listes

Les boucles qui construisent une nouvelle liste sont si courantes qu'elles ont des
formes courtes.

**`map`** fait une nouvelle liste en appliquant quelque chose à chaque élément :

```
> %team.people.map(*.name)
(Ada Bo Cy)
> %team.people.map(*.age)->sum
106
```

`*.name` est une **expression whatever** (« n'importe lequel ») : le `*` tient lieu de
« l'élément, quel qu'il soit ». `*.name` signifie « le `name` de l'élément », `*.age * 2`
signifie « deux fois son âge ». Pour quelque chose de plus long, utilisez un bloc, où le
topique est l'élément :

```
> %team.people.map({ .projects.map(*.stars)->sum })
(165 12 0)
```

C'est le nombre total d'étoiles des projets de chaque personne.

**`grep`** garde les éléments pour lesquels un test est vrai. Le nom vient du programme
Unix `grep`, qui garde les lignes qui correspondent :

```
> %team.people.grep(*.role eq 'dev').map(*.name)
(Bo)
> %team.people.grep(*.age > 30).map(*.name)
(Ada Cy)
```

**`first`** donne le premier élément qui passe le test, et arrête de chercher :

```
> %team.people.first(*.name eq 'Bo').manager
Ada
```

**`sort`** trie, selon l'élément lui-même ou selon ce que vous choisissez. Un signe
moins trie en sens inverse :

```
> %team.people->list.sort(*.age).map(*.name)
(Bo Ada Cy)
> %team.people->list.sort(-*.age).map(*.name)
(Cy Ada Bo)
```

**`unique`**, **`elems`**, **`sum`**, **`max`**, **`min`**, **`join`** finissent le
travail :

```
> my @projects = %team.people->list.map(*.projects->list)->flat
> @projects.map(*.name)
(rak irak myaml)
> @projects.map(*.tags->list)->flat->unique->sort
(data lang repl shell yaml)
> @projects.map(*.name)->join(', ')
rak, irak, myaml
```

`->flat` transforme une liste de listes en une seule longue liste : chaque personne
donne une liste de projets, et `->flat` les aligne tous.

Chacune de ces méthodes renvoie une nouvelle liste et laisse l'originale intacte ; vous
pouvez donc les enchaîner, et toujours revenir d'un pas avec `!!n`.

### 9.8 Profondeur inconnue : tout parcourir

`map` et `for` parcourent un niveau. Pour parcourir *tout*, à n'importe quelle
profondeur, il faut une routine qui s'appelle elle-même quand elle rencontre quelque
chose d'imbriqué : une routine **récursive**. En voici une qui affiche chaque chemin
d'une structure, avec sa valeur :

```
> sub walk($data, $path = '') {
...     given $data {
...         when Associative { for $data->keys->sort -> ~k { walk $data.~k, "$path.~k" } }
...         when Positional  { for $data->keys -> #i { walk $data.#i, "$path.#i" } }
...         default          { say "$path = $data" }
...     }
... }
> walk %team
.name = Orbit
.people.0.age = 36
.people.0.name = Ada
.people.0.projects.0.name = rak
.people.0.projects.0.stars = 120
.people.0.projects.0.tags.0 = lang
.people.0.projects.0.tags.1 = shell
.people.0.projects.1.name = irak
…
.people.2.role = ops
```

Comment cela marche, ligne par ligne :

- `sub walk($data, $path = '')` prend les données et le chemin parcouru jusqu'ici, vide
  au départ.
- `given $data` fait de `$data` le topique pour les lignes `when`.
- `when Associative` correspond aux hachages (ce qu'on consulte par clé). Pour chaque
  clé, dans l'ordre, elle rappelle `walk` sur la valeur sous cette clé, en ajoutant la
  clé au chemin.
- `when Positional` correspond aux tableaux (ce qu'on consulte par position). Idem, avec
  des positions.
- `default` correspond à tout le reste : une chaîne, un nombre. Il n'y a rien à
  parcourir à l'intérieur, donc elle affiche le chemin et la valeur.

Chaque appel traite un niveau et confie les niveaux inférieurs à de nouveaux appels
d'elle-même. C'est tout le secret de la récursivité : une routine qui résout une petite
partie du problème, et se fait confiance pour le reste. Elle marche à toute profondeur,
car elle n'a jamais eu besoin de connaître la profondeur.

Remarquez que les chemins affichés sont du rak valide : copiez
`.people.0.projects.1.name` après `%team` et vous obtenez `irak`. Remarquez aussi que le
tableau `projects` vide de Cy n'affiche rien : il n'y a rien dedans à afficher.

Pour le cas courant « appliquer quelque chose à chaque feuille », rak a une méthode toute
prête, `deepmap`, qui garde la structure et ne change que les feuilles :

```
> %team->deepmap(*->uc).people.1.name
BO
```

### 9.9 Chemins manquants

Un pas qui ne mène nulle part donne une valeur indéfinie, pas une erreur :

```
> %team.budget
(Any)
> %team.budget.total
(Any)
> %team.people.7.name
(Any)
```

C'est pratique quand on explore, et dangereux quand on calcule : une valeur indéfinie
utilisée comme nombre est traitée comme 0, avec un avertissement. Protégez-vous avec
`//` :

```
> %team.people.7.name // 'nobody'
nobody
```

Pour demander si une clé est présente, sans la lire, ajoutez `:exists` :

```
> %team.people.1.manager:exists
True
> %team.people.0.manager:exists
False
```

Ada n'a pas de responsable. `:delete` retire une entrée et rend sa valeur :

```
> %team.people.1.manager:delete
Ada
```

Lire un chemin manquant ne le crée jamais : `%team.budget.total`, plus haut, a laissé
`%team` inchangé. Seule l'affectation crée ce qui manque.

### Résumé

- `.clé` et `.position` font un pas dans un hachage ou un tableau. `.'clé'` et
  `."$clé"` pour les clés qui ne sont pas de simples mots.
- Les pas s'enchaînent en chemins : `%team.people.0.projects.1.name`. On peut affecter
  à un chemin.
- Un point en tête de ligne part du topique, une soumission à la fois. `<fichier` seul
  charge dans le topique.
- `.~k` et `.#i` font un pas contenu dans une variable `~` ou `#`. `.$k` est une erreur.
- Un point lit les données ; une flèche interroge la valeur (`.keys` contre `->keys`).
- `for … ->list { }`, `->kv`, les blocs pointus `-> $x { }` visitent les éléments.
- `map`, `grep`, `first`, `sort`, `unique`, `flat`, `join`, `sum` transforment les
  listes.
- Une routine récursive parcourt toute profondeur ; `deepmap` change chaque feuille.
- Un chemin manquant est indéfini : utilisez `//`, `:exists`, `:delete`.

### Exercices

1. En utilisant le topique, allez de `%team` au nombre d'étiquettes du premier projet
   d'Ada, un pas par soumission.
   <details><summary>Réponse</summary>

   ```
   > %team
   > .people
   > .0
   > .projects
   > .0
   > .tags
   > ->elems
   2
   ```
   Ou en une seule soumission : `%team.people.0.projects.0.tags->elems`.
   </details>

2. Listez les noms des personnes qui ont au moins un projet.
   <details><summary>Réponse</summary>

   ```
   > %team.people.grep(*.projects->elems > 0).map(*.name)
   (Ada Bo)
   ```
   </details>

3. Quels projets ont l'étiquette `shell` ?
   <details><summary>Réponse</summary>

   ```
   > @projects.grep({ 'shell' (elem) .tags }).map(*.name)
   (rak irak)
   ```
   `(elem)` demande « ceci est-il un élément de cette liste ? ».
   </details>

4. Modifiez `walk` pour qu'elle n'affiche que les chemins qui se terminent par `name`.
   <details><summary>Réponse</summary>

   Remplacez la ligne `default` par :
   ```
   default { say "$path = $data" if $path.ends-with('.name') }
   ```
   </details>

5. Calculez le total des étoiles de toute l'équipe.
   <details><summary>Réponse</summary>

   ```
   > @projects.map(*.stars)->sum
   177
   ```
   </details>

---

## 10. Désigner les données : noms, conteneurs, partage

Deux noms peuvent mener aux mêmes données, ou à deux copies de celles-ci. Modifiez les
données par un nom et, selon le cas où vous êtes, l'autre nom voit le changement ou non.
Ce chapitre apprend à distinguer les deux cas. Beaucoup de bogues déroutants, dans tous
les langages de programmation, viennent d'une confusion entre eux.

### 10.1 L'affectation copie

Affecter un tableau à un autre copie ses éléments :

```
> my @a = 1, 2, 3
[1 2 3]
> my @b = @a
[1 2 3]
> @b.0 = 99
99
> @a
[1 2 3]
> @b
[99 2 3]
```

`@a` et `@b` sont deux tableaux distincts. Modifier l'un laisse l'autre tranquille. Les
hachages se comportent de même : `my %copy = %team` fait un second hachage. Jusqu'ici,
rien que d'intuitif.

### 10.2 La liaison : un second nom pour la même chose

Parfois, vous *voulez* deux noms pour une même chose : un nom court pour quelque chose
de profondément enfoui dans une structure, par exemple. C'est la **liaison**
(*binding*), écrite `:=` au lieu de `=` :

```
> my @c := @a
[1 2 3]
> @c.0 = 42
42
> @a
[42 2 3]
```

`@c` n'est pas une copie. C'est un autre nom pour le même tableau, donc un changement
par `@c` est un changement de `@a`. L'affectation (`=`) met une valeur *dans* une boîte ;
la liaison (`:=`) fait qu'un nom *désigne* une boîte existante.

La liaison est surtout utile pour atteindre des données imbriquées. Au lieu de taper
`%team.people.0` encore et encore :

```
> my %ada := %team.people.0
{age => 36, name => Ada, projects => […], role => lead}
> %ada.role = 'architect'
architect
> %team.people.0.role
architect
```

`%ada` est une **référence** à l'entrée d'Ada dans `%team` : un nom qui mène à des
données stockées ailleurs. Modifier `%ada` modifie l'équipe.

Comparez avec l'affectation :

```
> my %bo = %team.people.1
{age => 29, manager => Ada, name => Bo, projects => […], role => dev}
> %bo.role = 'lead'
lead
> %team.people.1.role
dev
```

`%bo` est une copie, donc l'équipe est inchangée.

### 10.3 La surprise : les copies sont superficielles

Voici le cas qui piège tout le monde. Copiez toute l'équipe, puis modifiez une personne
dans la copie :

```
> my %copy = %team
> %copy.name = 'Orbit II'
Orbit II
> %team.name
Orbit
> %copy.people.2.age = 99
99
> %team.people.2.age
99
```

Changer le nom dans la copie a laissé l'original tranquille. Changer l'âge de Cy dans la
copie *l'a aussi changé dans l'original*. Pourquoi ?

Parce que `my %copy = %team` ne copie que le premier niveau : les clés `name` et
`people`, et leurs valeurs. La valeur de `people` est un tableau, et ce qui est copié est
une référence à ce tableau, pas le tableau lui-même. Les deux hachages pointent
maintenant vers le même tableau de personnes :

```
 %team ──┬── name ── "Orbit"
         └── people ─────────┐
                             ▼
                      [ Ada, Bo, Cy ]    ← un seul tableau, partagé
                             ▲
 %copy ──┬── name ── "Orbit II"
         └── people ─────────┘
```

`%copy.name = …` a remplacé une valeur au premier niveau, qui n'appartient qu'à
`%copy`. `%copy.people.2.age = …` est descendu dans le tableau partagé et l'a modifié là,
donc les deux hachages voient le changement.

Ce genre de copie est dit **superficiel** (*shallow*) : il copie un niveau et partage le
reste. C'est rapide, et c'est ce que fait toujours l'affectation. Rechargez avant de
continuer :

```
> my %team <team.json
```

### 10.4 Copier exprès

Pour copier aussi les niveaux inférieurs, il faut une copie **profonde** (*deep*), qui
copie chaque tableau et chaque hachage imbriqué. Le `deepmap` de rak, rencontré en
[9.8](#98-profondeur-inconnue--tout-parcourir), reconstruit chaque niveau d'une structure.
Si on lui demande de garder chaque feuille telle quelle (`*->self`), il produit une copie
profonde :

```
> my %deep = %team->deepmap(*->self)
> %deep.people.2.age = 99
99
> %team.people.2.age
41
```

Faites-en une routine, car vous en aurez encore besoin :

```
> sub deep-copy($x) { $x->deepmap(*->self) }
&deep-copy
```

Une autre copie profonde que vous connaissez déjà : enregistrer dans un fichier et
recharger. Encoder puis décoder du JSON reconstruit tout :

```
> %team >backup.json
> my %fresh <backup.json
```

`->clone` donne une copie superficielle, comme l'affectation, quand vous en avez besoin
comme valeur : `%team->clone`.

Quand utiliser quoi :

| Vous voulez… | Écrivez |
|---|---|
| un second nom pour les mêmes données | `my %x := …` (liaison) |
| un premier niveau indépendant, partageant ce qui est dessous | `my %x = …` (affectation) |
| une copie entièrement indépendante | `my %x = deep-copy …`, ou un aller-retour JSON |

### 10.5 Des boîtes dans des boîtes : l'itémisation

Au [9.6](#96-visiter-chaque-élément), boucler sur `%team.people` demandait `->list`.
Voici pourquoi.

Une variable `@` contient *plusieurs* choses. Une variable `$` contient *une* chose. Mais
vous pouvez mettre un tableau dans une variable `$` : c'est alors une seule chose, un
tableau, posé dans une boîte :

```
> my @a = 1, 2, 3
[1 2 3]
> my $s = @a
[1 2 3]
> for @a { print "<$_> " }
<1> <2> <3>
> for $s { print "<$_> " }
<1 2 3>
```

Boucler sur `@a` donne trois éléments. Boucler sur `$s` en donne *un* : le tableau, en
entier, dans sa boîte. Mettre une liste dans une seule boîte s'appelle l'**itémiser**
(en faire un *item*, un élément unique).

Toute valeur stockée dans un tableau ou un hachage se trouve dans une telle boîte. Donc
`%team.people` vous donne une boîte contenant un tableau : un seul item. C'est pourquoi
`for %team.people` ne ferait qu'un tour, et pourquoi `my @people = %team.people`
donnerait un tableau d'un seul élément, le tableau entier des personnes. `->list` sort le
tableau de sa boîte :

```
> (my @wrong = %team.people)->elems
1
> (my @right = %team.people->list)->elems
3
```

Les méthodes comme `map` et `grep` s'en moquent : `%team.people.map(*.name)` fonctionne,
car un appel de méthode atteint le tableau à travers la boîte.

L'inverse existe aussi. Un `|` devant une liste **glisse** (*slips*) ses éléments dans
la liste environnante, au lieu d'y mettre la liste comme un seul élément :

```
> my @x = 1, 2
[1 2]
> my @y = 3, 4
[3 4]
> (my @nested = @x, @y)->elems
2
> (my @slipped = |@x, |@y)->elems
4
```

`@x, @y` fait une liste de deux tableaux. `|@x, |@y` fait une liste de quatre nombres.

La règle pratique : **`->list` pour ouvrir une boîte, `|` pour déverser une liste dans
une autre.**

### 10.6 Passer des données aux routines

Quand vous appelez une routine, ses paramètres sont liés à vos arguments : la routine
voit vos données, pas une copie. Pour éviter les accidents, rak rend les paramètres
**en lecture seule** par défaut :

```
> sub birthday($person) { $person = 'changed' }
&birthday
> birthday %team.people.0
Cannot assign to a readonly variable or a value
```

Deux **traits**, écrits après le paramètre, changent cela :

- `is copy` : la routine reçoit sa propre copie, qu'elle peut modifier. Vos données sont
  à l'abri.
- `is rw` : « lecture-écriture » (*read-write*). La routine peut modifier votre
  variable, et vous voyez le changement.

```
> sub bump($n is rw) { $n = $n + 1 }
&bump
> my $v = 1
1
> bump $v
2
> $v
2
> sub local-bump($n is copy) { $n = $n + 1; $n }
&local-bump
> local-bump $v
3
> $v
2
```

Notez que la lecture seule protège le *paramètre*, pas ce qu'il contient. Une routine
qui reçoit un hachage peut quand même modifier ses entrées, puisque le hachage lui-même
est partagé :

```
> sub promote(%person) { %person.role = 'lead' }
&promote
> promote %team.people.1
lead
> %team.people.1.role
lead
```

Si une routine ne doit pas modifier vos données, donnez-lui une copie profonde.

### 10.7 Désigner du code

Les routines sont aussi des valeurs. Le sigil `&` nomme une routine *sans l'appeler* :

```
> &uc
&uc
> my &shout = &uc
&uc
> shout 'hey'
HEY
```

Cela permet de faire circuler des comportements, comme vous avez passé `*.name` à
`map` :

```
> sub twice(&f, $x) { f f $x }
&twice
> twice &flip, 'abc'
abc
> sub add-one($n) { $n + 1 }
&add-one
> twice &add-one, 5
7
```

`->&f` appelle une routine comme si c'était une méthode de la valeur :

```
> 'abc'->&flip
cba
```

Un bloc, lui aussi, est un morceau de code qu'on peut garder dans une variable. Un bloc
pointu avec des paramètres est une routine anonyme :

```
> my &area = -> $w, $h { $w * $h }
-> $w, $h { #`(Block|…) ... }
> area 3, 4
12
```

### 10.8 Les variables natives ne se partagent pas

Les variables `~` et `#` contiennent directement leur valeur, sans boîte. Sans boîte, un
second nom n'a rien vers quoi pointer ; on ne peut donc pas les lier :

```
> my ~s = 'a'
a
> my ~t := ~s
===SORRY!===
Can only compile an assign initializer on a native
```

L'affectation les copie, toujours. Cela participe à leur rapidité, et c'est rarement une
limite : un texte ou un nombre, cela se copie, cela ne se partage pas.

### 10.9 Même chose, ou choses égales ?

Deux sortes de questions :

- *Ces deux-là ont-ils la même valeur ?* `==` pour les nombres, `eq` pour les chaînes,
  et `eqv` pour des structures entières, comparées niveau par niveau.
- *Ces deux-là sont-ils le même objet ?* `===`, qui demande l'identité, pas la
  ressemblance.

```
> my @p = 1, 2
[1 2]
> my @q = 1, 2
[1 2]
> my @r := @p
[1 2]
> @p eqv @q
True
> @p === @q
False
> @p === @r
True
```

`@p` et `@q` sont égaux mais distincts, comme deux exemplaires du même livre. `@p` et
`@r` sont un seul tableau sous deux noms. Utilisez `eqv` pour comparer des données, et
`===` pour vérifier si deux noms les partagent.

### Résumé

- `=` copie dans une boîte ; `:=` fait qu'un nom désigne une boîte existante.
- Les copies sont superficielles : les tableaux et hachages imbriqués sont partagés.
  Utilisez `deep-copy` (via `deepmap`) ou un aller-retour JSON pour une copie complète.
- Les valeurs à l'intérieur des structures sont itémisées : `->list` ouvre la boîte, `|`
  glisse une liste dans une autre.
- Les paramètres sont en lecture seule ; `is copy` et `is rw` changent cela. Un contenu
  partagé peut quand même être modifié.
- `&nom` désigne une routine sans l'appeler ; `->&f` en appelle une comme une méthode.
- Les variables `~` et `#` ne peuvent pas être liées.
- `eqv` compare des valeurs ; `===` vérifie l'identité.

### Exercices

1. Après `my @a = 1, 2; my @b := @a; @b.push(3)`, que vaut `@a` ?
   <details><summary>Réponse</summary>

   `[1 2 3]` : `@b` est un autre nom pour `@a`.
   </details>

2. Après `my %c = %team; %c.people.0.name = 'Zed'`, que vaut `%team.people.0.name` ?
   Pourquoi ?
   <details><summary>Réponse</summary>

   `Zed`. La copie est superficielle : `%c` et `%team` partagent le même tableau de
   personnes, et le changement a été fait à l'intérieur.
   </details>

3. Écrivez `sub rename-all(%t)` qui renvoie une copie d'une équipe avec tous les noms en
   majuscules, sans modifier l'original.
   <details><summary>Réponse</summary>

   ```
   > sub rename-all(%t) { my %c = deep-copy %t; %c.people.map({ .name = .name->uc }); %c }
   &rename-all
   > rename-all(%team).people.map(*.name)
   (ADA BO CY)
   > %team.people.map(*.name)
   (Ada Bo Cy)
   ```
   </details>

4. Combien d'éléments a `my @z = [1, 2], [3, 4]` ? Et `my @z = |[1, 2], |[3, 4]` ?
   <details><summary>Réponse</summary>

   2, puis 4.
   </details>

---

# Partie IV : déplacer les données

Les données naissent rarement dans irak. Elles viennent de fichiers, d'autres
programmes, du web, et elles y retournent quand vous avez fini. La partie IV traite de
l'entrée et de la sortie des données : la redirection vers et depuis des fichiers, les
pipelines entre programmes et rak, et le web vu comme un endroit de plus où lire et
écrire.

## 11. Redirection et formats

Vous avez rencontré la redirection des commandes externes en
[5.6](#56-redirections-de-commandes). En rak, les mêmes flèches fonctionnent sur n'importe
quelle instruction, et elles comprennent les données, pas seulement le texte.

### 11.1 Redirection de sortie

`INSTR >fichier` exécute l'instruction en envoyant sa sortie dans `fichier` au lieu de
l'écran. Le fichier est d'abord vidé, ou créé s'il n'existe pas. `>>fichier` ajoute à la
fin à la place :

```
> say hello >greeting.txt
> say world >>greeting.txt
> cat greeting.txt
hello
world
```

La redirection ne dure que le temps de cette instruction. L'instruction suivante
affiche de nouveau à l'écran. Le fichier est fermé à la fin de l'instruction, même si
celle-ci échoue en cours de route.

Une instruction peut beaucoup afficher, et tout va dans le fichier :

```
> for 1..5 { say $_ * $_ } >squares.txt
> cat squares.txt
1
4
9
16
25
```

`1..5` est un **intervalle** (*range*) : les nombres de 1 à 5.

Seule la sortie standard est redirigée. `note` écrit sur l'erreur standard, qui atteint
toujours votre écran :

```
> note 'this is a warning' >log.txt
this is a warning
> cat log.txt
>
```

`log.txt` est vide.

### 11.2 Redirection d'entrée

`<fichier INSTR`, avec la flèche *avant* l'instruction, branche l'entrée standard de
l'instruction sur le fichier. En rak, l'entrée standard est `$*IN` :

```
> <greeting.txt say $*IN->lines->elems
2
> my $first
(Any)
> <greeting.txt $first = $*IN->get
hello
```

`->lines` lit toutes les lignes ; `->get` en lit une.

Les deux sens se combinent, l'entrée avant et la sortie après :

```
> <greeting.txt say $*IN->lines->reverse >reversed.txt
> cat reversed.txt
(world hello)
```

### 11.3 Le chargement : un fichier dans une variable

La forme que vous utiliserez le plus est le **chargement** (*load*) : `VARIABLE <fichier`,
avec la variable à *gauche* de la flèche. Il lit tout le fichier, le décode, et affecte
le résultat :

```
> my @lines <greeting.txt
[hello world]
> my $text <greeting.txt
hello
world
```

Avec une variable `@`, un fichier texte se charge comme une liste de lignes. Avec une
variable `$`, il se charge comme une seule chaîne.

Tout ce à quoi on peut affecter fonctionne à gauche, y compris un chemin dans une
structure :

```
> %team.notes <greeting.txt
hello
world
```

Et sans rien à gauche, un chargement va dans le topique. Vous l'avez déjà utilisé :

```
> <team.json
> .people.0.name
Ada
```

Notez la différence entre `<fichier INSTR`, qui branche l'entrée standard et laisse
l'instruction la lire, et `VARIABLE <fichier`, qui lit et décode le fichier pour vous.

### 11.4 Formats

L'extension du nom de fichier décide de son **format** : comment les valeurs deviennent
des octets à l'écriture, et redeviennent des valeurs à la lecture. Majuscules ou
minuscules, peu importe.

| Extension | Format | Écrit | Lit |
|---|---|---|---|
| `.json` | JSON | n'importe quelle valeur, joliment mise en forme : indentée, clés triées | une valeur |
| `.jsonl` | JSON Lines | une valeur JSON compacte par ligne | une liste de valeurs |
| toute autre | texte brut | du texte | des lignes (`@`) ou une chaîne (`$`) |

Le **JSON**, vous le connaissez depuis [8.7](#87-json-la-langue-commune-des-données). Il
écrit une valeur, sur autant de lignes que nécessaire.

**JSON Lines** écrit une valeur par ligne, chacune sur une seule ligne. Il convient aux
enregistrements : une ligne par personne, par événement, par entrée de journal. On peut
ajouter un enregistrement avec `>>`, ce que JSON ne permet pas :

```
> %team.people >people.jsonl
> cat people.jsonl
{"age":36,"name":"Ada","projects":[…],"role":"lead"}
{"age":29,"manager":"Ada","name":"Bo","projects":[…],"role":"dev"}
{"age":41,"manager":"Ada","name":"Cy","projects":[],"role":"ops"}
> { name => 'Di', age => 24, role => 'intern', projects => [] } >>people.jsonl
> my @everyone <people.jsonl
> @everyone->elems
4
```

Le sigil à gauche d'un chargement doit convenir au contenu :

```
> my @list <team.json       # il faut un tableau JSON
> my %h <team.json          # il faut un objet JSON : marche
> my $x <team.json          # accepte n'importe quoi
> my @r <people.jsonl       # une liste d'enregistrements
```

Avec une variable comme cible, `>$fichier`, le format est choisi à l'exécution de
l'instruction, d'après la valeur de la variable :

```
> my $out = 'ada.json'
ada.json
> %team.people.0 >$out
```

### 11.5 Mode valeur et mode texte

Comment `%team >team.json` sait-il qu'il doit écrire la *valeur* de `%team`, alors que
`say hello >greeting.txt` écrit le *texte affiché* ? En regardant ce qu'a fait
l'instruction :

```
                  l'instruction a-t-elle affiché quelque chose ?
                 ┌──────────────┴──────────────┐
                oui                           non
                 │                             │
            MODE TEXTE                    MODE VALEUR
  le texte affiché est écrit.      la valeur de l'instruction est encodée
  si la cible a un format, le      dans le format de la cible et écrite.
  texte doit déjà être dans ce     (sans format : le fichier reste
  format ; rak le vérifie et le    vide.)
  réécrit proprement.
```

Le mode valeur est ce qu'il vous faut pour des données :

```
> %team >team.json            # le hachage, en JSON
> 1/3 >third.json             # 0.3333333333333333
> 'hi' >hi.json               # "hi"
```

Le mode texte est ce qu'il vous faut pour du texte, et il vérifie quand même les cibles
JSON. Un texte affiché qui est presque du JSON est accepté et nettoyé, ce qui est
commode pour taper du JSON à la main :

```
> print q[{ a: 'a', }] >t.json
> cat t.json
{
  "a": "a"
}
```

Les clés n'avaient pas de guillemets, les chaînes avaient des apostrophes, et il y avait
une virgule finale : rien de tout cela n'est du JSON strict, tout est corrigé. (`q[…]`
est une autre façon d'écrire une chaîne entre apostrophes, utile quand le texte
lui-même contient des guillemets.)

Un texte affiché qui n'est pas du tout du JSON est refusé :

```
> say (1, 2) >t2.json
t2.json: invalid JSON at line 1, column 1: unexpected '('
```

`say` a affiché `(1 2)`, la façon dont rak montre une liste, pas du JSON. Retirez le
`say` pour écrire la valeur à la place : `(1, 2) >t2.json`.

### 11.6 Quand un format échoue

Chaque erreur de format nomme le fichier et dit ce qui ne va pas. La cible reste
intacte : un enregistrement raté ne laisse jamais un fichier à moitié écrit.

| Message | Cause | Remède |
|---|---|---|
| `cannot encode as json: a value of type Set has no JSON form` | la valeur n'a pas de forme JSON | la convertir d'abord : `->list`, `->Str` |
| `invalid JSON at line 2, column 1: unexpected end of input` | le fichier à charger n'est pas du JSON valide | regarder cette ligne du fichier |
| `expected a JSON object for %h, found an array` | mauvais sigil pour le contenu | `@` pour les tableaux, `%` pour les objets, `$` pour n'importe quoi |
| `cannot append to a .json target, use .jsonl for one record per line` | `>>` sur un fichier `.json` | utiliser `.jsonl`, ou réécrire tout le fichier |

Un fichier manquant, ou que vous n'avez pas le droit d'écrire, donne aussi une erreur
qui le nomme.

### 11.7 L'espacement fait partie de la syntaxe

Une flèche de redirection **touche** son nom de fichier. Une comparaison a des
**espaces** des deux côtés. C'est ainsi que rak les distingue :

```
> my $a = 3
3
> $a > 2           # comparaison : $a est-il plus grand que 2 ?
True
> say $a >two      # redirection : afficher 3 dans le fichier « two »
> say $a > 2       # comparaison, affichée
True
```

Un nom de fichier qui commence par un chiffre n'est pas une cible : `say $a >2` serait
ambigu, et rak refuse de deviner. Écrivez `>'2'` si vous voulez vraiment un fichier
appelé `2`. Le chargement `<5` est l'exception, et rak vous en avertit :

```
> $a <5
Potential difficulties:
    `<5` loads the file '5'; put a space after `<` to compare
```

Les hyperopérateurs, que vous n'avez pas rencontrés, sont espacés aussi : `@a >>+<< @b`
reste ce qu'il est. Dans le doute, suivez la règle : **opérateurs espacés, redirections
collées.**

### Résumé

- `INSTR >fichier` et `INSTR >>fichier` envoient la sortie dans un fichier ;
  `<fichier INSTR` lit l'entrée depuis un fichier. Pour une seule instruction.
- `VARIABLE <fichier` charge et décode un fichier ; `<fichier` seul charge dans le
  topique.
- L'extension choisit le format : `.json`, `.jsonl`, ou texte brut.
- Le mode valeur écrit la valeur de l'instruction quand elle n'a rien affiché ; le mode
  texte écrit le texte affiché, vérifié selon le format.
- Les erreurs de format nomment le fichier et le laissent intact.
- `>` espacé compare ; `>` collé à un nom redirige.

### Exercices

1. Enregistrez les noms de l'équipe, un par ligne, dans `names.txt`, puis rechargez-les
   dans un tableau.
   <details><summary>Réponse</summary>

   ```
   > for %team.people->list { say .name } >names.txt
   > my @names <names.txt
   [Ada Bo Cy]
   ```
   </details>

2. Enregistrez les mêmes noms sous forme de tableau JSON dans `names.json`. Quel mode
   est utilisé ?
   <details><summary>Réponse</summary>

   `%team.people.map(*.name) >names.json`. Rien n'est affiché, donc mode valeur : la
   liste est encodée en tableau JSON.
   </details>

3. Pourquoi `my %h <names.json` échoue-t-il ? Qu'est-ce qui marcherait ?
   <details><summary>Réponse</summary>

   `names.json` contient un tableau, et `%h` attend un objet. `my @h <names.json` ou
   `my $h <names.json` marche.
   </details>

4. Ajoutez un enregistrement de journal avec l'heure courante à `log.jsonl` chaque fois
   que vous exécutez une soumission. (`DateTime->now->Str` donne l'heure sous forme de
   texte.)
   <details><summary>Réponse</summary>

   ```
   > { when => DateTime->now->Str, what => 'tested' } >>log.jsonl
   ```
   Rappelez-la avec `!n` pour ajouter d'autres enregistrements. Un `DateTime` en
   lui-même n'a pas de forme JSON, d'où le `->Str`.
   </details>

---

## 12. Pipelines

### 12.1 L'idée d'Unix

Dans les années 1970, les créateurs d'Unix ont eu une idée qui façonne encore notre usage
des ordinateurs : écrire de petits programmes qui font chacun une chose bien, et les
brancher de sorte que la sortie de l'un soit l'entrée du suivant. Le branchement est un
**tube** (*pipe*), écrit `|`. Une chaîne de programmes reliés par des tubes est un
**pipeline**.

```
> cat fruit.txt
pear
apple
plum
apple
> cat fruit.txt | ^sort | ^uniq -c
      2 apple
      1 pear
      1 plum
```

`cat` affiche le fichier. Sa sortie standard, au lieu d'aller à l'écran, va dans
l'entrée standard de `sort`, qui trie les lignes. Cette sortie-là va dans `uniq -c`, qui
fusionne les lignes répétées et les compte. Seule la sortie du dernier programme atteint
votre écran. Les trois programmes tournent en même temps, chacun traitant ce que produit
le précédent, comme sur une chaîne de montage.

(Le `^` force les programmes externes `sort` et `uniq`, car rak a des routines de ces
noms ; voir [5.3](#53-qui-lemporte-pour-un-nom).)

Chaque maillon du pipeline est une **étape** (*stage*). Les tubes relient des étapes,
tandis que les redirections, du [chapitre 11](#11-redirection-et-formats), relient une
instruction à un fichier.

### 12.2 Les étapes rak

Dans un shell Unix, chaque étape est un programme, et tout ce qui passe entre elles est
du texte. En rak, une étape peut aussi être un morceau de rak : une méthode, un chemin
pointé, un bloc ou une routine. Ces étapes se passent des **valeurs**, pas du texte, et
tournent dans irak, sans lancer aucun processus.

```
> cat fruit.txt | ->unique
(pear apple plum)
```

`cat` est un programme. `->unique` est une méthode rak. Entre les deux, rak transforme
la sortie de `cat` en liste de lignes, et appelle `->unique` sur cette liste.

Chaque sorte d'étape rak reçoit la valeur *entière* venue de la gauche, la valeur
**amont** :

| Étape | Signifie | Exemple |
|---|---|---|
| `->meth` ou `.meth(…)` | appeler une méthode sur la valeur amont | `->unique`, `.head(3)` |
| `.chemin` | y prendre un chemin pointé | `.people`, `.0.name` |
| `{ bloc }` | exécuter le bloc avec le topique `$_` égal à elle | `{ .map(*.age)->sum }` |
| `nom args` | appeler une routine, avec la valeur amont comme dernier argument | `map *.name`, `grep *.age > 30` |
| `from-json` | la décoder comme un document JSON | `cat x.json \| from-json` |
| `from-jsonl` | la décoder comme du JSON Lines : une valeur par ligne | `cat x.jsonl \| from-jsonl` |

### 12.3 Des pipelines sans aucun processus

Puisqu'un chargement est une étape, un pipeline peut partir d'un fichier et rester en
rak de bout en bout, un peu comme le programme `jq` :

```
> <team.json | .people | map *.name
(Ada Bo Cy)
> <team.json | .people | map *.age | ->sum
106
> <team.json | .people | grep *.projects->elems > 0 | map *.name
(Ada Bo)
```

Lisez-le de gauche à droite, comme une phrase : charger l'équipe, prendre ses membres,
garder ceux qui ont des projets, prendre leurs noms. Comparez avec la même chose écrite
en une seule expression :

```
> (my %t <team.json).people.grep(*.projects->elems > 0).map(*.name)
(Ada Bo)
```

Les deux sont corrects. Le pipeline se lit dans l'ordre où vous pensez, une étape après
l'autre, et vous pouvez le faire grandir une étape à la fois : exécuter les deux
premières étapes, regarder, en ajouter une troisième.

Un pipeline peut commencer de trois façons : par une commande (`cat fruit.txt | …`), par
un chargement (`<team.json | …`), ou par un chemin pointé en tête, qui part du topique :

```
> <team.json
> .people | map *.role
(lead dev ops)
```

### 12.4 Là où les octets rencontrent les valeurs

Quand un programme et une étape rak se rencontrent, rak convertit entre octets et
valeurs :

**Programme → étape rak.** La sortie du programme devient une liste de lignes, sans
leurs sauts de ligne. La liste est **paresseuse** (*lazy*) : les lignes sont lues à
mesure que l'étape rak les demande, pas toutes d'un coup
([12.7](#127-paresse-et-sigpipe)). Pour décoder plutôt la sortie comme des données,
ajoutez une étape `from-json` ou `from-jsonl` :

```
> cat team.json | from-json | .people.1.name
Bo
> cat people.jsonl | from-jsonl | map *.name
(Ada Bo Cy Di)
```

**Étape rak → programme.** La valeur est écrite comme du texte sur l'entrée standard du
programme :

| La valeur est | Écrite comme |
|---|---|
| une chaîne ou un nombre | une ligne |
| une liste | une ligne par élément |
| un hachage, ou une liste de hachages ou de listes | JSON Lines : un enregistrement compact par ligne |

```
> <team.json | .people | map *.name | ^sort -r
Cy
Bo
Ada
> <team.json | .people | ^grep Bo
{"age":29,"manager":"Ada","name":"Bo","projects":[…],"role":"dev"}
```

Dans le second exemple, chaque personne est devenue une ligne de JSON, et le `grep`
externe a gardé la ligne contenant `Bo`.

**Programme → programme.** Un vrai tube, comme dans n'importe quel shell Unix. Les
octets passent intacts, et rak n'intervient pas.

### 12.5 Quand `|` est un tube

`|` a d'autres sens en rak, hérités de Raku : `1 | 2` est une **jonction**, une valeur
qui signifie « 1 ou 2 », et `|@a` glisse une liste
([10.5](#105-des-boîtes-dans-des-boîtes--litémisation)). Pour garder ces sens, `|` n'est un tube
que lorsque :

1. la ligne *commence* comme un pipeline : par une commande, un chargement (`<fichier`),
   ou un chemin pointé en tête (`.people`) ; et
2. le `|` est espacé, avec une espace de chaque côté.

Partout ailleurs, c'est une jonction. En particulier, une variable ne commence pas un
pipeline :

```
> my @names = 'Bo', 'Ada'
[Bo Ada]
> @names | ^sort
Must specify something to sort
```

`@names | ^sort` est une jonction de `@names` et d'un appel à `sort` sans argument, qui
échoue.

Mettez la valeur dans le topique et partez de lui avec `.[]`, « tous les éléments du
topique » :

```
> $_ = @names
[Bo Ada]
> .[] | ^sort
Ada
Bo
```

### 12.6 Les pipelines comme valeurs

En début de ligne, un pipeline montre son résultat : la sortie d'un programme va à
l'écran, et la valeur d'une étape rak est affichée par irak. Entre parenthèses, le
pipeline est une valeur qu'on peut ranger ou transmettre :

```
> my @people = (<team.json | .people)
> @people->elems
3
> my $count = (cat fruit.txt | ->elems)
4
```

Si la dernière étape est un programme, la valeur est sa sortie, sous forme de chaîne,
comme pour une commande seule en [5.4](#54-utiliser-la-sortie-dune-commande-comme-valeur) :

```
> my $sorted = (cat fruit.txt | ^sort)
apple
apple
pear
plum
```

### 12.7 Paresse et SIGPIPE

Le programme `yes` affiche `y` indéfiniment. Il ne s'arrête jamais de lui-même. Pourtant,
ceci se termine aussitôt :

```
> ^yes | ->head(2)
(y y)
```

Deux choses font que cela marche.

D'abord, la **paresse** : l'étape rak `->head(2)` demande deux lignes, et seules deux
sont lues. Rien dans rak n'attend « toute » la sortie de `yes`.

Ensuite, **SIGPIPE** : une fois que `->head(2)` a ce qu'il lui faut, elle arrête de
lire. La prochaine fois que `yes` écrit, personne n'écoute, et le système lui envoie le
signal `SIGPIPE` ([3.7](#37-arrêter-un-processus)), qui l'arrête. Il se passe la même
chose entre deux programmes, comme dans tout shell :

```
> yes | head -2
y
y
```

> [!CAUTION]
> 🔴 **Ne se comporte pas (encore) comme décrit.** `^yes | ->head(2)` marche, mais le
> pipeline de programme à programme `yes | head -2` n'affiche actuellement rien, et `@?`
> contient alors un seul statut au lieu de deux.

Une étape arrêtée par `SIGPIPE` n'est pas comptée comme un échec : on lui a dit de
s'arrêter, elle n'est pas cassée.

La paresse explique pourquoi un pipeline sur un énorme fichier commence aussitôt à
produire des résultats, et pourquoi il n'a pas besoin de tenir tout le fichier en
mémoire.

### 12.8 Statut de sortie d'un pipeline

Un pipeline compte plusieurs programmes, donc plusieurs statuts de sortie. rak les garde
tous dans `@?`, dans l'ordre, et met le plus utile dans `$?` : **le premier programme
qui a échoué, ou le dernier si aucun n'a échoué**. (Les habitués des shells connaissent
cela sous le nom de `pipefail`.)

```
> false | true
exit 1
> $?->exitcode
1
> @?.map(*->exitcode)
(1 0)
```

`false` a échoué, donc `$?` est son statut, bien que `true`, à la fin, ait réussi. Un
pipeline fait uniquement d'étapes rak ne change ni `$?` ni `@?`.

### 12.9 Rediriger un pipeline

> [!CAUTION]
> 🔴 **Ne se comporte pas (encore) comme décrit.** Aujourd'hui, un pipeline qui se
> termine par une étape rak et redirigé vers un fichier `.json` écrit `[]`, et vers un
> fichier `.jsonl` s'arrête sur `Type Str does not support associative indexing`. Un
> pipeline qui se termine par un programme s'arrête sur l'erreur du
> [5.6](#56-redirections-de-commandes). Enregistrez plutôt la valeur du pipeline :
> `my @names = (<team.json | .people | map *.name); @names >names.json`.

Un pipeline est une instruction ; il peut donc se terminer par une redirection. Avec une
étape rak à la fin, la valeur est enregistrée dans le format de la cible :

```
> <team.json | .people | map *.name | ->sort >names.json
> cat names.json
[
  "Ada",
  "Bo",
  "Cy"
]
> cat fruit.txt | ->unique >fruit.jsonl
> cat fruit.jsonl
"pear"
"apple"
"plum"
```

Avec un programme à la fin, sa sortie est redirigée, comme pour toute commande :

```
> cat fruit.txt | ^sort | ^uniq >fruit-set.txt
```

### Résumé

- Un pipeline relie des étapes par un `|` espacé : la sortie de chacune est l'entrée de
  la suivante.
- Les étapes sont des programmes (octets) ou des étapes rak (valeurs) : `->meth`,
  `.chemin`, `{ bloc }`, `nom args`, `from-json`, `from-jsonl`.
- Un pipeline commence par une commande, un chargement ou un chemin pointé en tête.
  Sinon, `|` est une jonction.
- La sortie d'un programme devient des lignes paresseuses ; les valeurs rak deviennent
  des lignes ou du JSON Lines.
- Entre parenthèses, un pipeline est une valeur.
- La paresse et `SIGPIPE` permettent aux pipelines de s'arrêter tôt.
- `$?` est le premier échec (ou le dernier statut) ; `@?` les contient tous.

### Exercices

1. Listez les étiquettes distinctes utilisées par l'équipe, triées, avec un pipeline.
   <details><summary>Réponse</summary>

   ```
   > <team.json | .people | { .map(*.projects->list)->flat.map(*.tags->list)->flat } | ->unique | ->sort
   (data lang repl shell yaml)
   ```
   </details>

2. Comptez combien de lignes de `/etc/passwd` mentionnent `bash`, avec un programme
   puis une étape rak.
   <details><summary>Réponse</summary>

   ```
   > cat /etc/passwd | grep *.contains('bash') | ->elems
   ```
   Le nombre dépend de votre système. Ou entièrement avec des programmes :
   `grep -c bash /etc/passwd`.
   </details>

3. Pourquoi `@names | ^sort` ne trie-t-il pas ?
   <details><summary>Réponse</summary>

   Un pipeline doit commencer par une commande, un chargement ou un chemin pointé en
   tête. Une variable n'en commence pas un, donc `|` est l'opérateur de jonction.
   Écrivez `$_ = @names; .[] | ^sort`.
   </details>

4. Enregistrez les membres de l'équipe en JSON Lines, à l'aide d'un pipeline, et comptez
   les enregistrements avec `wc -l`.
   <details><summary>Réponse</summary>

   ```
   > <team.json | .people >people.jsonl
   > wc -l people.jsonl
   3 people.jsonl
   ```
   </details>

---

## 13. Le web comme un fichier : les cibles URL

Lire depuis une URL, publier vers une URL, les identifiants et les erreurs fonctionnent
aujourd'hui. Quelques parties du chapitre restent des projets, et le disent dans un
encadré rouge : la routine `http` ([13.5](#135-les-autres-sortes-de-requêtes--http)), les
pages ([13.8](#138-pages)), et les réponses JSON Lines et binaires du
[13.3](#133-ce-qui-revient).

### 13.1 Clients, serveurs et URL

Quand votre navigateur affiche une page web, il mène une conversation avec un autre
ordinateur, souvent à l'autre bout de la planète. Votre navigateur est le **client** :
il demande. L'autre ordinateur fait tourner un **serveur**, un processus
([chapitre 3](#3-processus)) qui attend des questions et y répond. La langue de cette
conversation est **HTTP** (*HyperText Transfer Protocol*), et sa forme sécurisée,
chiffrée en chemin, est **HTTPS**.

Chaque question désigne son objet par une **URL** (*Uniform Resource Locator*), une
adresse pour quelque chose sur le web :

```
https://api.github.com/repos/rakudo/rakudo/issues?state=open
└─┬─┘   └─────┬──────┘└────────────┬─────────────┘└───┬────┘
schéma       hôte                chemin            requête
```

- le **schéma** dit comment parler : `https` ;
- l'**hôte** dit quel ordinateur : `api.github.com` ;
- le **chemin** dit quoi, sur cet ordinateur, un peu comme un chemin de fichier ;
- la **requête** (*query*), après `?`, ajoute des options : des paires `clé=valeur`
  séparées par `&`.

Beaucoup de serveurs répondent par des données plutôt que par des pages web : du JSON, la
plupart du temps. Un tel serveur est une **API** (*Application Programming Interface*),
un service fait pour les programmes plutôt que pour les gens. GitHub, les services météo,
les registres de paquets et la plupart des outils que vous utilisez au travail en ont
une.

Pour rak, une URL est un endroit où vivent des données, comme un fichier. Les mêmes
flèches fonctionnent donc.

### 13.2 Lire : `<url`

Un chargement depuis une URL la récupère :

```
> <https://api.github.com/repos/rakudo/rakudo
> .full_name
rakudo/rakudo
> .stargazers_count
1734
> .license.name
Artistic License 2.0
```

Exactement comme avec `<team.json`, la réponse est devenue le topique, et vous la
parcourez avec des points. Chargez-la dans une variable pour la garder :

```
> my %repo <https://api.github.com/repos/rakudo/rakudo
> %repo.open_issues_count
1203
```

(Vos nombres seront différents : ils sont en direct.)

En coulisse, rak a envoyé une **requête** HTTP **GET**, celle qu'envoie votre navigateur
quand vous ouvrez une page : « donne-moi ce qui se trouve à cette URL ». La réponse du
serveur est une **réponse** (*response*) : un **code de statut** qui dit comment cela
s'est passé, quelques **en-têtes** (*headers*, des faits étiquetés sur la réponse), et un
**corps** (*body*), le contenu lui-même.

### 13.3 Ce qui revient

Le format d'un fichier vient de son extension. Le format d'une réponse vient de son
en-tête `Content-Type`, que le serveur fixe pour dire ce qu'est le corps :

| `Content-Type` | Vous obtenez |
|---|---|
| `application/json` (ou tout ce qui finit par `+json`) | des données : hachages, tableaux, chaînes, nombres |
| `application/x-ndjson` (JSON Lines) | une liste d'enregistrements, lue paresseusement |
| `text/…` (`text/plain`, `text/html`, …) | une chaîne |
| tout le reste (images, archives, …) | des octets bruts, un `Blob` |

Une chaîne se charge comme un fichier texte : entière dans `$` ou `~`, ligne par ligne
dans `@`.

```
> my ~license <https://raw.githubusercontent.com/rakudo/rakudo/main/LICENSE
> ~license->lines->head(1)
(		       The Artistic License 2.0)
> my @lines <https://raw.githubusercontent.com/rakudo/rakudo/main/LICENSE
> @lines->elems
201
```

> [!CAUTION]
> 🔴 **Ne se comporte pas (encore) comme décrit.** Les réponses JSON Lines et binaires ne
> sont pas encore décodées : aujourd'hui, tout `Content-Type` qui n'est pas du JSON donne
> une chaîne. L'exemple `$logo` ci-dessous ne marchera pas.

```
> my $logo <https://raku.org/camelia-logo.png
> $logo->elems
14562
```

Le `->elems` d'un `Blob` est sa taille en octets. Pour garder les octets,
enregistrez-les : `$logo >camelia.png`. Un fichier dont l'extension n'est pas un format
de données reçoit les octets tels quels.

### 13.4 Écrire : `INSTR >url`

Écrire vers une URL **envoie** quelque chose au serveur. rak envoie une requête HTTP
**POST**, celle qu'envoie un formulaire web : « voici quelque chose de nouveau,
prends-le ». Ce qui est envoyé suit les modes valeur et texte du
[11.5](#115-mode-valeur-et-mode-texte) :

- si l'instruction n'a rien affiché, sa **valeur** est envoyée en JSON ;
- si elle a affiché, le **texte affiché** est envoyé. Comme pour un fichier `.json`, il
  doit être du JSON, et c'est vérifié avant que quoi que ce soit ne quitte votre
  ordinateur.

La plupart des API attendent du JSON ; vous enverrez donc surtout des valeurs :

```
> { title => 'Docs: typo in chapter 3', body => 'Missing word.' } >https://api.github.com/repos/me/notes/issues
{number => 42, state => open, title => Docs: typo in chapter 3, url => https://…, …}
```

Le serveur a répondu par le ticket (*issue*) qu'il a créé, et irak montre cette réponse :
avec une cible URL, la réponse décodée est la valeur de l'instruction, et elle devient
donc le topique. Parcourez-la :

```
> .number
42
> .html_url
https://github.com/me/notes/issues/42
```

Quand le serveur répond par rien (le statut `204 No Content`), la valeur est `Nil`.

La sortie d'un programme s'envoie de la même façon : `cat draft.json >https://…` publie
ce que `cat` a affiché, qui doit lui aussi être du JSON.

`>>url` n'a pas de sens (on ne peut pas « ajouter à la fin » d'un service web) et est une
erreur, tout comme `<url INSTR` et `2>url`. rak les refuse avant de rien exécuter.

### 13.5 Les autres sortes de requêtes : `http`

GET et POST sont les requêtes les plus courantes, et les flèches vous les donnent. HTTP a
quelques autres **méthodes**, chacune un verbe différent :

| Méthode | Signifie | Usage typique |
|---|---|---|
| GET | donne-moi | lire quelque chose |
| POST | prends cette chose nouvelle | créer quelque chose |
| PUT | remplace par ceci | écraser entièrement quelque chose |
| PATCH | change ces champs | mettre à jour une partie de quelque chose |
| DELETE | retire | supprimer quelque chose |

> [!CAUTION]
> 🔴 **Pas encore implémenté.** La routine `http` n'existe pas encore. D'ici là, un
> programme fait le travail :
> `curl -s -X PATCH -H 'Content-Type: application/json' -d '…' URL`.

La routine `http` vous les donne toutes, avec la méthode en premier mot. Un corps, quand
il y en a un, est envoyé en JSON :

```
> http patch https://api.github.com/repos/me/notes/issues/42 { state => 'closed' }
{number => 42, state => closed, …}
> http delete https://api.example.com/drafts/7
> http get https://api.github.com/repos/rakudo/rakudo
{full_name => rakudo/rakudo, …}
```

Comme avec `INSTR >url`, la réponse décodée est la valeur, et devient le topique.
`http get URL` équivaut à `<URL` ; il existe pour que toutes les méthodes s'écrivent de
la même façon.

### 13.6 Écrire des URL

Une cible URL commence par `http://` ou `https://`. Elle court jusqu'à une espace, un
`;`, un `#`, une accolade ou une parenthèse. Les variables de sigil `$` s'y interpolent :

```
> my $owner = 'rakudo'
rakudo
> <https://api.github.com/repos/$owner/rakudo
> .full_name
rakudo/rakudo
```

Seules les variables `$` s'interpolent. Un `~` est courant dans les URL
(`https://example.com/~ada/`) : `~` y reste donc un caractère ordinaire, et un `#`
commencerait un commentaire. Pour une variable `~` ou `#`, ou tout autre code, mettez
l'URL entre guillemets : dans une chaîne entre guillemets doubles, tout s'interpole
([4.3](#43-chaînes--nues-et-entre-guillemets)) :

```
> my ~repo = 'rakudo'
rakudo
> my #n = 5
5
> <"https://api.github.com/repos/$owner/{~repo}/issues?per_page={#n * 2}"
> ->elems
10
```

Le nom d'une variable finit là où finit un nom Raku, et `-` peut faire partie d'un nom :
`<https://example.com/$owner-fork` lit la variable `$owner-fork`. Mettez des guillemets
et des accolades : `<"https://example.com/{$owner}-fork"`. Une URL qui contient une
espace doit aussi être entre guillemets : `<"https://example.com/my file.txt"`. (Dans une
URL, une espace s'écrit généralement `%20`, qui n'a pas besoin de guillemets.)

### 13.7 Identifiants : des en-têtes tirés d'un fichier de configuration

La plupart des API veulent savoir qui vous êtes avant de vous laisser écrire, et beaucoup
avant de vous laisser lire. Vous le prouvez avec un **jeton** (*token*), une longue
chaîne secrète que le service vous donne, envoyée dans un en-tête avec chaque requête.

Taper un secret dans vos commandes le laisserait dans votre historique, et dans vos
scripts. rak lit donc les en-têtes dans un fichier de configuration,
`~/.config/rak/http-headers.json`, et les ajoute à chaque requête envoyée à l'hôte
correspondant :

```
// ~/.config/rak/http-headers.json
{
  'api.github.com': {
    auth: '$GITHUB_TOKEN',
    Accept: 'application/vnd.github+json',
  },
  'api.example.com': { 'X-Api-Key': '$EXAMPLE_KEY' },
}
```

Le fichier est lu comme du JSON souple ([11.5](#115-mode-valeur-et-mode-texte)) :
commentaires, apostrophes simples, clés sans guillemets, virgules finales. Mettez entre
guillemets une clé qui contient un `.` ou un `-`.

- Chaque clé de premier niveau est un hôte (ou `hôte:port`). Ses entrées sont les
  en-têtes à y envoyer.
- `'$NOM'` est remplacé par la variable d'environnement `NOM`
  ([3.2](#32-ce-que-porte-chaque-processus)) : le secret lui-même peut ainsi rester hors du
  fichier. Quand `NOM` n'est pas définie, l'en-tête n'est pas envoyé.
- `auth: JETON` abrège l'en-tête `Authorization: Bearer JETON`, la façon la plus courante
  d'envoyer un jeton.

Pour `api.github.com`, si aucun `auth` n'est configuré, rak en demande un à l'outil en
ligne de commande de GitHub (`gh auth token`) : si vous utilisez `gh`, GitHub marche sans
aucune configuration.

rak n'écrit jamais ce fichier : créez-le vous-même, avec son répertoire
(`mkdir -p ~/.config/rak`). Si la variable `XDG_CONFIG_HOME` est définie, rak regarde
plutôt dans `$XDG_CONFIG_HOME/rak/`.

### 13.8 Pages

> [!CAUTION]
> 🔴 **Pas encore implémenté.** rak ne suit pas encore les pages : un chargement ne donne
> que la première. Demandez des pages plus grandes avec une option de requête, comme
> `?per_page=100` sur GitHub.

Une API qui a beaucoup de résultats les envoie par **pages** : les 30 premiers tickets,
par exemple, et un en-tête nommé `Link` qui dit où se trouve la page suivante. rak suit
ces liens pour vous, et paresseusement :

```
> my $issues <https://api.github.com/repos/rakudo/rakudo/issues
> $issues.head(5).map(*.title)
(…cinq titres…)
```

Avec une variable `$`, rak ne récupère une page que lorsque vous avez besoin de son
contenu : ici, seulement la première. Avec une variable `@`, rak récupère toutes les
pages d'un coup, puisqu'un tableau contient tous ses éléments :

```
> my @all <https://api.github.com/repos/rakudo/rakudo/issues
> @all->elems
1203
```

Cela peut faire beaucoup de requêtes. Utilisez `$` et `->head` pour explorer ; utilisez
`@` quand vous voulez vraiment tout. Une option de requête réduit souvent le travail :
`?state=open&labels=docs`.

### 13.9 Quand le serveur dit non

Chaque réponse porte un code de statut. Dans les 200, tout s'est bien passé. Dans les
400, le problème vient de votre requête : `404` « introuvable », `401` « qui êtes-vous ? »,
`403` « interdit », `422` « je ne comprends pas ce que vous avez envoyé ». Dans les 500,
le problème vient du serveur.

Pour un statut 4xx ou 5xx, rak lève une erreur, un `X::Rak::HTTP`, avec l'URL, le
statut et le message du serveur lui-même :

```
> <https://api.github.com/repos/rakudo/no-such-repo
https://api.github.com/repos/rakudo/no-such-repo: HTTP 404: Not Found
```

Le message est le champ `message` d'une réponse JSON, ce que la plupart des API envoient,
ou sinon la première ligne de la réponse. Quand aucune réponse ne revient (pas de
réseau, un nom d'hôte erroné), l'erreur est aussi un `X::Rak::HTTP`, sans statut.

Un échec ne change rien : un `my %repo <url` qui échoue laisse `%repo` tel quel, et un
POST dont le texte affiché n'est pas du JSON n'envoie rien.

Vous apprendrez à intercepter les erreurs en [15.5](#155-quand-les-choses-tournent-mal).

### 13.10 Fichiers et URL ensemble

> [!CAUTION]
> 🔴 **Ne se comporte pas (encore) comme décrit.** Un chargement suivi d'une redirection
> de sortie, comme `<url >fichier` ou `<fichier >url`, est refusé aujourd'hui, pour les
> fichiers comme pour les URL. Utilisez deux instructions : `<url; $_ >rakudo.json`, et
> `my %d <draft.json; %d >url`.

Puisque fichiers et URL sont tous deux des cibles, vous pouvez déplacer des données de
l'un à l'autre en une seule instruction :

```
> <https://api.github.com/repos/rakudo/rakudo >rakudo.json
> my %r <rakudo.json
```

Enregistrer une réponse dans un fichier et travailler à partir du fichier est une bonne
habitude : c'est plus rapide, cela marche hors ligne, et cela ne compte pas dans les
limites de l'API. Envoyer des données depuis un fichier est tout aussi court :

```
> <draft.json >https://api.github.com/repos/me/notes/issues
```

`<draft.json` charge le fichier ; la valeur de l'instruction est ces données, que `>url`
envoie.

### 13.11 Ce dont un shell traditionnel aurait besoin

Vous avez maintenant vu les trois choses qui distinguent irak de bash, zsh ou fish : il
**comprend les données** (JSON, JSON Lines), il **parcourt les structures** avec des
chemins pointés, et il traite **le web comme un fichier**. Un shell traditionnel ne
connaît que le texte : une variable contient une chaîne, un tube transporte des octets,
une redirection vise un fichier. Tout le reste est confié à des programmes auxiliaires,
surtout **`jq`**, qui lit et remodèle le JSON, et **`curl`**, qui parle HTTP. Les deux
sont excellents ; le prix à payer est que chacun a son propre petit langage, et que les
règles de guillemets du shell se superposent aux deux.

Voici les mêmes tâches dans irak et dans bash. Chaque ligne bash est la façon habituelle
de faire.

> [!CAUTION]
> 🔴 **Pas encore implémenté.** Le suivi des pages et la routine `http` n'existent pas
> encore. Les autres exemples fonctionnent aujourd'hui.

**Lire un champ d'un fichier JSON.**

```
> <team.json | .people.0.name                    # irak
$ jq -r '.people[0].name' team.json              # bash + jq
```

Le chemin est presque le même : jq a inspiré les chemins pointés de rak. Mais en bash,
le fichier est relu et décodé à chaque appel de `jq`, et le résultat redevient du texte
ensuite.

**Garder les données, poser plusieurs questions.**

```
> my %team <team.json                             # irak : décodé une fois
> %team.people->elems
3
> %team.people.grep(*.age > 30).map(*.name)
(Ada Cy)
```

```
$ jq '.people | length' team.json                                  # bash + jq
3
$ jq -r '.people[] | select(.age > 30) | .name' team.json
Ada
Cy
```

Une variable bash ne peut contenir qu'une chaîne ; il n'y a donc nulle part où garder
`%team` sous forme de données : chaque question retourne au fichier. Le `select`, le
`.[]` et le `length` de jq sont un second langage à apprendre à côté de celui du shell.

**Modifier une valeur et enregistrer.**

```
> %team.people.0.age = 37; %team >team.json       # irak
```

```
$ jq '.people[0].age = 37' team.json > team.tmp && mv team.tmp team.json   # bash + jq
```

Le fichier temporaire n'est pas décoratif. `jq … team.json > team.json` viderait
`team.json` *avant* que jq le lise, car le shell ouvre la cible en premier : une façon
classique de perdre un fichier. rak n'écrit la cible qu'une fois la valeur prête
([11.6](#116-quand-un-format-échoue)).

**Charger depuis le web.**

```
> <https://api.github.com/repos/rakudo/rakudo      # irak
> .stargazers_count
```

```
$ curl -s https://api.github.com/repos/rakudo/rakudo | jq .stargazers_count   # bash
```

**Envoyer un jeton.** irak le prend dans `~/.config/rak/http-headers.json`
([13.7](#137-identifiants--des-en-têtes-tirés-dun-fichier-de-configuration)), une fois pour toutes. curl en a
besoin à chaque ligne :

```
$ curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user | jq -r .login
```

**Envoyer du JSON.**

```
> my $title = 'Docs: typo in chapter 3'            # irak
> { title => $title, body => 'Missing word.' } >https://api.github.com/repos/me/notes/issues
> .number
42
```

```
$ title='Docs: typo in chapter 3'                  # bash + jq + curl
$ jq -n --arg t "$title" --arg b 'Missing word.' '{title: $t, body: $b}' |
    curl -s -X POST \
         -H "Authorization: Bearer $GITHUB_TOKEN" \
         -H 'Content-Type: application/json' \
         --data @- https://api.github.com/repos/me/notes/issues |
    jq .number
42
```

Pourquoi `jq -n --arg` ? Parce que construire le JSON en collant `$title` dans une
chaîne casse dès que le titre contient un guillemet. Dans irak, le hachage *est* la
donnée, et rak l'encode.

**Suivre les pages.** irak suit `Link: rel="next"` tout seul ([13.8](#138-pages)). Avec
curl, vous écrivez une boucle qui lit les en-têtes de réponse, extrait l'URL suivante, et
concatène les pages avec `jq -s 'add'` ; ou vous utilisez un outil propre au service,
comme `gh api --paginate`.

**Savoir quelle étape d'un pipeline a échoué.**

```
> false | true; $?->exitcode                       # irak : pipefail par défaut
1
```

```
$ set -o pipefail; false | true; echo $?           # bash : sur demande
1
$ false | true; echo "${PIPESTATUS[@]}"            # tous les statuts, jusqu'à la commande suivante
1 0
```

En résumé :

| Tâche | bash | irak |
|---|---|---|
| décoder du JSON | `jq` à chaque appel | `<fichier.json`, une fois |
| garder des données structurées dans une variable | impossible : chaînes seulement | `%`, `@`, `$` |
| parcourir une structure | le langage de jq | chemins pointés, `map`, `grep` |
| enregistrer du JSON sur place | fichier temporaire et `mv` | `%data >fichier.json` |
| HTTP GET, POST, PATCH | `curl` avec des options | `<url`, `>url`, `http` |
| en-têtes d'authentification | `-H` à chaque appel | un fichier de configuration |
| pagination | une boucle écrite à la main | automatique, paresseuse |
| échecs dans un pipeline | `set -o pipefail`, `PIPESTATUS` | `$?`, `@?` |

Rien de tout cela ne rend jq ou curl obsolètes : ils sont toujours là, et irak les lance
comme n'importe quel programme ([16](#16-et-ensuite-)). irak rend simplement les cas
courants longs d'une ligne, dans un seul langage.

Pour d'autres tâches GitHub côte à côte avec `curl`, `jq` et Raku pur (lire un dépôt,
lister des commits, ouvrir un ticket, commenter), voir [`PLANS/demos/github.md`](PLANS/demos/github.md) dans le dépôt.

### Résumé

- Une URL désigne quelque chose sur le web. Un serveur répond aux requêtes HTTP qui la
  concernent.
- `<url` envoie un GET ; `INSTR >url` envoie un POST de JSON (la valeur, ou un texte
  affiché qui doit être du JSON) ; `>>url` est une erreur.
- `http patch|put|delete|get URL [CORPS]` enverra les autres méthodes (pas encore).
- Le `Content-Type` de la réponse choisit sa forme : des données pour du JSON, une chaîne
  sinon (enregistrements et octets sont prévus). La réponse à un POST devient la valeur
  de l'instruction et le topique.
- `$var` s'interpole dans une URL nue. Pour `~var`, `#var` et `{expr}`, et pour les
  espaces, mettez l'URL entre guillemets doubles.
- En-têtes et jetons vivent dans `~/.config/rak/http-headers.json` ; `auth:` est un
  jeton *bearer* ; pour GitHub, rak se rabat sur `gh auth token`.
- Les pages seront suivies paresseusement dans `$`, d'un coup dans `@` (pas encore).
- Un statut 4xx ou 5xx, ou l'absence de réponse, lève `X::Rak::HTTP`, et la cible reste
  telle quelle.

### Exercices

1. Chargez les données GitHub d'un dépôt que vous aimez, et affichez sa description et
   son nombre d'étoiles.
   <details><summary>Réponse</summary>

   ```
   > <https://api.github.com/repos/rakudo/rakudo
   > say .description, ' — ', .stargazers_count
   ```
   </details>

2. Enregistrez les tickets ouverts de ce dépôt qui ont l'étiquette `docs` dans
   `docs-issues.json`, puis listez leurs titres à partir du fichier.
   <details><summary>Réponse</summary>

   ```
   > <https://api.github.com/repos/rakudo/rakudo/issues?labels=docs&per_page=100; $_ >docs-issues.json
   > <docs-issues.json | map *.title
   ```
   Tant que rak ne suit pas les pages, seule la première est enregistrée :
   `&per_page=100` la rend aussi grande que GitHub le permet.
   </details>

3. Qu'envoie `say 'hello' >https://httpbin.org/post`, et comment ?
   <details><summary>Réponse</summary>

   Rien : `say` a affiché, donc mode texte, et le `hello` affiché n'est pas du JSON. rak
   lève un `X::Rak::Format::Decode` avant d'envoyer quoi que ce soit. Sans `say`,
   `'hello' >https://httpbin.org/post` envoie la chaîne JSON `"hello"`, tout comme
   `say '"hello"' >https://httpbin.org/post`.
   </details>

---

# Partie V : tout assembler

## 14. Une session complète

Ce chapitre est une session irak du début à la fin, comme vous pourriez vraiment
travailler. Rien n'y est nouveau ; il montre comment s'assemblent les pièces de tous les
chapitres précédents. La tâche : vous maintenez un petit projet sur GitHub, et vous
voulez un rapport hebdomadaire des tickets qui attendent une réponse depuis le plus
longtemps, enregistré dans un fichier et publié en commentaire sur le ticket de suivi de
votre projet.

### 14.1 Où suis-je ?

```
[0] > pwd
/home/ada
[1] > mkdir -p reports; cd reports
[2] > ls
[3] >
```

Un répertoire vide où travailler ([chapitre 2](#2-fichiers-et-répertoires)). Puisque `ls`
n'a rien affiché, il est vide.

### 14.2 Récupérer

```
[3] > my $owner = 'ada'; my $repo = 'orbit'
orbit
[4] > my @open <https://api.github.com/repos/$owner/$repo/issues?state=open&per_page=100; @open >open.json
[5] > ls -l
-rw-r--r-- 1 ada ada 184211 Nov 20 09:12 open.json
```

Une requête, chargée dans `@open` et enregistrée dans un fichier ([13.10](#1310-fichiers-et-url-ensemble)).
Désormais, vous travaillez à partir du fichier, et l'API n'est plus dérangée.

### 14.3 Jeter un œil

```
[6] > <open.json
[7] > ->elems
37
[8] > .0->keys->sort
(assignee body comments created_at html_url labels number pull_request state title updated_at user …)
[9] > .0.title
Crash when the config file is empty
[10] > .0.user.login
yuki
[11] > .0.comments
0
```

Trente-sept tickets ouverts. Chacun est un hachage, avec un `title` (titre), un `user`
(lui-même un hachage, avec un `login`), un nombre de `comments` (commentaires), une date
`created_at` (de création), et bien d'autres.

Certains de ces « tickets » sont des *pull requests* (demandes de fusion) : GitHub
renvoie les deux depuis la même URL. Une pull request a une clé `pull_request`.
Écartez-les :

```
[12] > !!6
[13] > .grep(!*.pull_request) >issues.json
[14] > <issues.json | ->elems
29
```

`!!6` a ramené la liste complète ([6.3](#63-rappeler-des-soumissions-précédentes)), et le
`grep` a gardé ceux *sans* entrée `pull_request` : `!` signifie « non ».

### 14.4 Répondre à une question

Quels tickets n'ont aucun commentaire, du plus ancien au plus récent ?

```
[15] > <issues.json | grep *.comments == 0 | ->sort(*.created_at) | map { .number, .title }
((12 Crash when the config file is empty) (19 Docs: install on Windows) (23 Support YAML anchors) …)
```

Les dates sont du texte au format `2026-03-14T08:21:05Z`, qui se trie dans l'ordre
chronologique en tant que texte ; trier par `created_at` trie donc par âge.

Depuis combien de temps chacun attend-il ? Transformez le texte en date, et
soustrayez :

```
[16] > sub age-in-days(~stamp) { (DateTime->now - DateTime.new(~stamp))->Int div 86400 }
&age-in-days
[17] > age-in-days '2026-03-14T08:21:05Z'
251
```

`DateTime.new` lit une date et `DateTime->now` est l'heure courante. Soustraire deux dates
donne une durée en secondes, `->Int` en retire la partie décimale, et `div 86400`
transforme les secondes en jours entiers (`div` est la division sans partie décimale).

### 14.5 Mettre en forme le rapport

Construisez un petit hachage par ticket, avec seulement ce dont le rapport a besoin :

```
[18] > my @issues <issues.json
[19] > my @waiting = @issues
...      .grep(*.comments == 0)
...      .sort(*.created_at)
...      .map({ %( number => .number, title => .title, days => age-in-days(.created_at),
...                url => .html_url ) });
[20] > @waiting->elems
11
[21] > @waiting.0
{days => 251, number => 12, title => Crash when the config file is empty, url => https://github.com/ada/orbit/issues/12}
```

Les mêmes étapes que le pipeline de la soumission 15, écrites comme une **chaîne de
méthodes** : chaque ligne commence par un point et continue la précédente, ce qui permet
d'étaler une longue expression sur plusieurs lignes. `%( … )` fait un hachage à partir
d'une liste de paires. Dans un bloc, il rend l'intention claire : un simple
`{ number => … }` entre accolades marcherait aussi, mais `%(…)` ne peut pas être pris
pour un bloc.

Enregistrez les données, pour la comparaison de la semaine prochaine :

```
[22] > @waiting >waiting-2026-11-20.json
```

### 14.6 Écrire le texte

Le rapport est en Markdown, le format de texte dans lequel est écrit ce tutoriel :

```
[23] > sub report(@items) {
...        say "## Issues waiting for a first answer";
...        say '';
...        for @items -> %i {
...            say "- [#{%i.number}]({%i.url}) {%i.title} — {%i.days} days";
...        }
...    }
&report
[24] > report @waiting
## Issues waiting for a first answer

- [#12](https://github.com/ada/orbit/issues/12) Crash when the config file is empty — 251 days
- [#19](https://github.com/ada/orbit/issues/19) Docs: install on Windows — 198 days
…
[25] > report @waiting >report.md
```

`report @waiting` a affiché à l'écran, pour vérifier. `!!` l'aurait répété ; ajouter une
redirection a envoyé la même sortie dans un fichier ([11.1](#111-redirection-de-sortie)).

### 14.7 Publier

L'API de GitHub crée un commentaire sur le ticket 1 quand vous envoyez par POST
`{ body => … }` à `/repos/PROPRIÉTAIRE/DÉPÔT/issues/1/comments` :

```
[26] > my $text <report.md
[27] > { body => $text } >https://api.github.com/repos/$owner/$repo/issues/1/comments
{body => ## Issues waiting…, html_url => https://github.com/ada/orbit/issues/1#issuecomment-…, …}
[28] > .html_url
https://github.com/ada/orbit/issues/1#issuecomment-2483119
```

Le jeton est venu de `gh` ([13.7](#137-identifiants--des-en-têtes-tirés-dun-fichier-de-configuration)). La
réponse est le nouveau commentaire, qui est devenu le topique, et son `html_url` est un
lien à ouvrir dans votre navigateur.

### 14.8 Ce qui s'est passé

En 28 soumissions, vous avez utilisé :

- le système de fichiers : `pwd`, `mkdir`, `cd`, `ls` (chapitres 2 et 5) ;
- un chargement d'URL enregistré dans un fichier, puis des chargements depuis le fichier
  (chapitres 11 et 13) ;
- le parcours depuis le topique, `!!n` (chapitres 6 et 9) ;
- `grep`, `sort`, `map` comme étapes de pipeline (chapitres 9 et 12) ;
- une routine avec un paramètre `~`, et un `DateTime` (chapitres 7 et 10) ;
- un hachage par enregistrement, enregistré en JSON (chapitre 8) ;
- une routine qui affiche, redirigée vers un fichier (chapitre 11) ;
- un POST vers une API, sa réponse comme topique (chapitre 13).

La semaine prochaine, vous voudrez le même rapport. Retaper 28 lignes, ce n'est pas une
vie : le chapitre suivant transforme cette session en script.

---

## 15. D'irak à un script `.rak`

### 15.1 Les scripts

Un **script** est un fichier de code rak qui s'exécute du début à la fin, sans que vous
tapiez chaque ligne. C'est ainsi qu'une session devient un outil. Un script rak a un nom
qui finit par `.rak`, et s'exécute avec la commande `rak` :

```
$ cat hello.rak
say 'hello from a script';
$ rak hello.rak
hello from a script
```

(Le `$` au début de ces lignes est l'invite du shell du système, pas celle d'irak : on
lance les scripts depuis un terminal, ou depuis irak lui-même avec la commande
`rak hello.rak`.)

Ce qui est pareil que dans irak : tout ce que vous avez appris. Chaînes nues, sigils,
chemins pointés, redirections, cibles URL, pipelines.

Ce qui diffère :

| irak | script |
|---|---|
| la valeur de chaque soumission est montrée | rien n'est montré si vous ne le `say`-ez pas |
| `$_` contient la valeur précédente | `$_` n'est fixé que par `for`, `given`, les blocs |
| `!!n`, `!n` | pas d'historique |
| les instructions sont séparées par la touche Entrée | les instructions finissent par `;` |

Les deux premières différences comptent le plus. Dans un script, écrivez `say` là où
irak aurait montré une valeur, et utilisez des variables là où vous utilisiez le
topique.

### 15.2 Transformer la session en script

Prenez les lignes utiles du [chapitre 14](#14-une-session-complète), laissez tomber
l'exploration, et nommez les choses :

```
# waiting.rak — liste les tickets qui attendent une première réponse, les plus anciens d'abord.

my $owner = 'ada';
my $repo  = 'orbit';

sub age-in-days(~stamp) { (DateTime->now - DateTime.new(~stamp))->Int div 86400 }

sub report(@items) {
    say "## Issues waiting for a first answer";
    say '';
    for @items -> %i {
        say "- [#{%i.number}]({%i.url}) {%i.title} — {%i.days} days";
    }
}

my @open <https://api.github.com/repos/$owner/$repo/issues?state=open&per_page=100;

my @waiting = @open
    .grep({ !.pull_request && .comments == 0 })
    .sort(*.created_at)
    .map({ %( number => .number, title => .title,
              days => age-in-days(.created_at), url => .html_url ) });

report @waiting >report.md;
say "{@waiting->elems} issues written to report.md";
```

Les lignes qui commencent par `#` et une espace sont des commentaires : pour le lecteur
humain, ignorés par rak. Le premier commentaire dit à quoi sert le script. Écrivez-en un
en tête de chaque script ; vous vous en remercierez dans six mois.

La chaîne de `.grep`, `.sort`, `.map` remplace le pipeline : dans un script, les chaînes
de méthodes étalées sur plusieurs lignes se lisent bien aussi. Chaque ligne commence par
un point, et continue la précédente.

### 15.3 Les arguments : `MAIN`

Le propriétaire et le dépôt sont écrits dans le script. Pour l'utiliser avec n'importe
quel projet, prenez-les sur la ligne de commande. Nommez une routine `MAIN`, et rak
l'appelle avec les arguments du script ([3.5](#35-comment-un-processus-se-termine)) :

```
sub MAIN($owner, $repo, #min-days = 0) {
    my @open <https://api.github.com/repos/$owner/$repo/issues?state=open&per_page=100;
    my @waiting = @open
        .grep({ !.pull_request && .comments == 0 })
        .map({ %( number => .number, title => .title,
                  days => age-in-days(.created_at), url => .html_url ) })
        .grep(*.days >= #min-days)
        .sort(-*.days);
    report @waiting >report.md;
    say "{@waiting->elems} issues written to report.md";
}
```

```
$ rak waiting.rak ada orbit 30
11 issues written to report.md
$ rak waiting.rak
Usage:
  waiting.rak <owner> <repo> [<#min-days>]
```

rak lit les paramètres de `MAIN` et fait le reste : il vérifie les arguments, convertit
`30` en nombre pour `#min-days`, et affiche un message d'**usage** quand ils ne
conviennent pas. Un paramètre avec une valeur par défaut, comme `#min-days = 0`, est
facultatif.

Les arguments sont aussi disponibles sous forme de simple liste, dans `@*ARGS`.

### 15.4 Faire d'un script une commande

Deux étapes rendent un script exécutable par son seul nom, comme `ls`.

1. Une première ligne qui dit quel programme l'exécute, le **shebang** (d'après les
   caractères `#!`, « hash-bang ») :

   ```
   #!/usr/bin/env rak
   ```

   `/usr/bin/env rak` signifie « le `rak` trouvé dans mon `$PATH` »
   ([3.3](#33-comment-un-programme-est-trouvé--path)).

2. La permission de l'exécuter ([2.4](#24-regarder-de-plus-près--ls--l-et-ls--a)) :

   ```
   $ chmod +x waiting.rak
   $ ./waiting.rak ada orbit
   ```

Pour le lancer de n'importe où, placez-le dans un répertoire listé dans votre `$PATH`,
comme `~/.local/bin`, et laissez tomber le `./`.

### 15.5 Quand les choses tournent mal

Un script tourne sans que vous le surveilliez. Quand quelque chose échoue, il doit dire
quoi, et s'arrêter proprement. Par défaut, une erreur arrête le script avec un message
et le statut de sortie 1, ce qui suffit souvent. Pour traiter une erreur vous-même,
entourez la partie risquée d'un `try`, et examinez l'erreur dans un bloc `CATCH` :

```
my @open = try {
    CATCH {
        when X::Rak::HTTP {
            note "GitHub said {$_->status} for {$_->url}";
            exit 2;
        }
    }
    my @o <https://api.github.com/repos/$owner/$repo/issues?state=open;
    @o
}
```

Dans `CATCH`, l'erreur est le topique. `when X::Rak::HTTP` choisit les erreurs HTTP
([13.9](#139-quand-le-serveur-dit-non)) ; `->status` et `->url` lui demandent deux de ses
parties. `note` écrit sur l'erreur standard : le message ne se mélange donc pas au
rapport si la sortie est redirigée. `exit 2` arrête le script avec le statut 2, qu'un
appelant peut tester avec `$?->exitcode`.

`die 'message'` lève une erreur à vous, quand votre script détecte un problème :

```
die "no issues found for $owner/$repo" unless @open;
```

### 15.6 L'exécuter chaque semaine

Une fois qu'un script tourne sans poser de questions, le système peut l'exécuter pour
vous. Sous Linux, l'outil classique est `cron` : une ligne dans votre crontab
(`crontab -e`) exécute une commande à heures fixes :

```
# minute heure jour-du-mois mois jour-de-la-semaine   commande
  0      8     *            *    1                    cd ~/reports && ~/.local/bin/waiting.rak ada orbit
```

Chaque lundi à 8 h. La sortie d'une tâche cron vous est envoyée par courrier, ou perdue,
selon le système ; les scripts lancés par cron devraient donc écrire leurs résultats
dans des fichiers, comme celui-ci.

### 15.7 Un second exemple : `stars.rak`

Un court script sur le fichier d'équipe du [chapitre 8](#8-structures-de-données-complexes),
pour revoir une fois de plus les pièces principales :

```
#!/usr/bin/env rak
# stars.rak — total des étoiles par personne, au moins MIN.

sub MAIN($file = 'team.json', #min = 0) {
    my %team <$file;
    for %team.people->list -> %p {
        my #s = %p.projects.map(*.stars)->sum;
        say "{%p.name}: #s" if #s >= #min;
    }
}
```

```
$ ./stars.rak
Ada: 165
Bo: 12
Cy: 0
$ ./stars.rak team.json 20
Ada: 165
```

Notez `"{%p.name}"` dans la chaîne. Entre guillemets doubles, écrivez un chemin pointé
entre accolades : un simple `%p.name` ne serait pas lu comme un chemin.

### Résumé

- Un script `.rak` s'exécute du début à la fin. Rien n'est montré si vous ne l'affichez
  pas ; il n'y a ni historique ni topique transmis d'une ligne à l'autre.
- `sub MAIN(…)` reçoit les arguments de la ligne de commande, les vérifie, et écrit un
  message d'usage.
- `#!/usr/bin/env rak` et `chmod +x` font d'un script une commande.
- `try` avec `CATCH`/`when` traite les erreurs ; `note` et `exit` les signalent ; `die`
  en lève une.
- `cron` exécute des scripts selon un calendrier.

### Exercices

1. Écrivez `count.rak`, qui prend un nom de fichier et affiche son nombre de lignes, à
   l'aide d'un chargement.
   <details><summary>Réponse</summary>

   ```
   sub MAIN($file) {
       my @lines <$file;
       say @lines->elems;
   }
   ```
   </details>

2. Ajoutez à `stars.rak` une option facultative `--json` qui enregistre le résultat en
   JSON au lieu de l'afficher. (Un paramètre écrit `Bool :$json` est une option :
   `--json` le met à `True`.)
   <details><summary>Réponse</summary>

   ```
   sub MAIN($file = 'team.json', $min = 0, Bool :$json) {
       my %team <$file;
       my %stars = %team.people->list.map({ .name => .projects.map(*.stars)->sum })
                                      .grep(*->value >= $min);
       if $json { %stars >stars.json } else { for %stars->sort { say "{$_->key}: {$_->value}" } }
   }
   ```
   Le `key` et le `value` d'une paire sont des méthodes, d'où les flèches. (`#min` serait
   plus joli, mais un paramètre `#` à côté d'une option nommée trouble actuellement
   `MAIN`.)
   </details>

3. Que se passe-t-il si `waiting.rak` s'exécute dans un répertoire où vous n'avez pas le
   droit d'écrire ?
   <details><summary>Réponse</summary>

   La récupération marche, mais `>report.md` échoue avec une erreur qui nomme
   `report.md`. Le script s'arrête avec un message et le statut de sortie 1.
   </details>

---

## 16. Et ensuite ?

Vous avez fait un long chemin : de ce que sont un fichier et un processus, en passant
par les variables, les données imbriquées et les références, jusqu'aux pipelines, au web
et aux scripts. Quelques directions à partir d'ici.

**Pratiquez sur vos propres données.** La meilleure façon d'apprendre est d'utiliser
irak pour quelque chose dont vous avez déjà besoin : l'export JSON d'une application,
votre historique de shell, un fichier de journal au travail. Chargez-le, parcourez-le,
posez des questions.

**Gardez l'aide-mémoire à portée de main.** `CHEATSHEET.md`, à la racine du dépôt rak,
liste toute la syntaxe propre à rak en quelques pages.

**Lisez le glossaire.** `GLOSSARY.md` définit les termes qu'emploie rak, avec le sens
exact de chacun dans le projet.

**Apprenez davantage de Raku.** rak, c'est Raku avec des ajouts : tout livre, tutoriel et
réponse en ligne sur Raku s'applique, une fois connues les quelques différences.
L'[annexe A](#annexe-a--rak-et-raku-chapitre-par-chapitre) les recense, chapitre par
chapitre. La documentation officielle est sur <https://docs.raku.org> ; « Think Raku » et
« Raku Fundamentals » sont des livres accessibles aux débutants (en anglais). Raku offre
bien des choses que ce tutoriel n'a pas abordées : classes et objets, grammaires pour
analyser n'importe quel texte, concurrence avec promesses et *supplies*, et un vaste
écosystème de modules.

**Apprenez le shell lui-même.** rak exécute les programmes de votre système, et plus
vous en connaissez, plus vous pouvez en faire. `man` suivi d'un nom de commande affiche
son manuel : `man sort`, `man find`. « The Linux Command Line », de William Shotts, est
gratuit en ligne et excellent.

**Apprenez jq.** Si vous travaillez avec du JSON venu du web, `jq` est l'outil standard.
Ses chemins ressemblent aux chemins pointés de rak, et vous pouvez l'appeler depuis irak
comme n'importe quel programme : `<data.json | ^jq '.items[] | .name'`.

**Connaissez les limites.** rak est jeune. Certaines décisions sont encore ouvertes, et
listées dans le dépôt sous `PLANS/`. Quand quelque chose vous surprend, consultez
l'[annexe B](#annexe-b--les-pièges), puis le gestionnaire de tickets, et signalez ce que
vous avez trouvé : une surprise pour vous en est une aussi pour le prochain débutant.

**Essayez une vraie API.** Celle de GitHub est un bon terrain de jeu : ses réponses sont
en JSON, et ses données publiques ne demandent pas de jeton. [`PLANS/demos/github.md`](PLANS/demos/github.md) liste les points
d'accès utiles, avec rak à côté de `curl`, `jq` et Raku pur.

Bon bidouillage !

---

# Annexes

## Annexe A : rak et Raku, chapitre par chapitre

rak est un frontal pour Raku : le même langage, avec des ajouts, actifs seulement dans
les fichiers qui finissent par `.rak` et dans irak. Tout ce qui existe en Raku marche en
rak, avec les exceptions listées ici. Cette annexe s'adresse aux lecteurs qui
connaissent Raku, ou qui liront plus tard des documents sur Raku.

### Chapitres 1–3 : le REPL et les processus

| rak | Raku |
|---|---|
| irak, lancé par `rak` | le REPL de Raku, lancé par `raku` |
| la valeur d'une soumission devient `$_` | le REPL ne fixe pas le topique |
| rappel d'historique `!!n`, `!n` | absent du REPL de Raku |
| un simple nom de commande lance un programme : `ls -l` | `run 'ls', '-l'`, ou `shell 'ls -l'` |
| `$?` (dernier statut), `@?` (tous, pour un pipeline) | `$?` n'est pas utilisé ; `run` renvoie un `Proc` |
| `$?->exitcode`, `$?->signal` | `$proc.exitcode`, `$proc.signal` |

### Chapitre 4 : les valeurs

| rak | Raku |
|---|---|
| chaînes nues : `say hello` | `say 'hello'` (un simple `hello` est un appel de routine) |
| la juxtaposition passe plusieurs arguments : `f foo bar` | `f 'foo', 'bar'` |
| `->meth` appelle une méthode sans argument | `.meth` |
| `.mot` est un indice | `.mot` est un appel de méthode ; les indices s'écrivent `{'mot'}` ou `<mot>` |

Les deux dernières lignes sont le plus grand changement. En rak, `.` lit les données et
`->` interroge la valeur. En Raku, `.` interroge la valeur, et les données se lisent avec
`{ }`, `< >` ou `[ ]`. `->` garde son sens Raku, un bloc pointu, partout où un terme est
attendu : `for @a -> $x { }`.

### Chapitre 5 : les commandes

| rak | Raku |
|---|---|
| `type NOM` montre ce que signifie un nom | pas d'équivalent |
| une routine rak l'emporte sur un programme du même nom ; `^nom` force le programme | pas de programmes par leur nom |
| `cd` est une commande interne qui change `$*CWD` | `chdir`, ou affecter à `$*CWD` |
| la sortie d'une commande entre parenthèses est une chaîne : `(git branch)` | `run(…, :out).out.slurp` |
| les commandes inconnues sont une erreur de compilation, vérifiée d'après `$PATH` | — |

### Chapitre 7 : les sigils

| rak | Raku |
|---|---|
| `my ~s` | `my str $s` |
| `my #n` | `my int $n` |
| `.~k`, `.#i` indice avec une variable native | `{$k}`, `[$i]` |
| `-> ~k`, `-> #i` dans les signatures | `-> str $k`, `-> int $i` |
| `#nom` est une variable ; `# ` suivi d'une espace est un commentaire | `#` commence toujours un commentaire |

### Chapitre 9 : les indices pointés

| rak | Raku |
|---|---|
| `%h.name` | `%h<name>` ou `%h{'name'}` |
| `@a.1` | `@a[1]` |
| `%h.'two words'` | `%h{'two words'}` |
| `%h."$k"` | `%h{$k}` |
| `%h.~k` | `%h{$k}` (avec `str $k`) |
| `@a.#i` | `@a[$i]` (avec `int $i`) |
| `.people.0.name` (depuis le topique) | `.<people>[0]<name>` |
| `%h.k:exists`, `%h.k:delete` | `%h<k>:exists`, `%h<k>:delete` |
| `%h.$k` est une erreur | `%h.$k` appelle la méthode contenue dans `$k` |
| `.5` est la position 5 du topique | `.5` est le nombre 0,5 |

Les formes à crochets marchent toujours en rak : `%h<name>`, `@a[1]` et `%h{$k}` sont
tous acceptés.

### Chapitre 10 : les références

Rien ne change : liaison, conteneurs, itémisation, `is rw`, `is copy`, `eqv` et `===`
sont ceux de Raku. `->list` est `.list`, `->clone` est `.clone`, `->deepmap(…)` est
`.deepmap(…)`.

### Chapitre 11 : la redirection

| rak | Raku |
|---|---|
| `INSTR >fichier`, `INSTR >>fichier` | `{ temp $*OUT = open('fichier', :w); INSTR }` |
| `<fichier INSTR` | `{ temp $*IN = open('fichier'); INSTR }` |
| `my %h <fichier.json` | `my %h = from-json slurp 'fichier.json'` |
| `%h >fichier.json` (mode valeur) | `spurt 'fichier.json', to-json %h, :sorted-keys` |
| cibles `.jsonl` | rien d'intégré |
| l'espacement décide : `$a > 2` contre `$a >two` | `>` est toujours la comparaison |

### Chapitre 12 : les pipelines

| rak | Raku |
|---|---|
| `cmd | ^sort` | `run 'cmd', :out` puis `run 'sort', :in($p.out)` |
| `… | ->meth`, `… | .chemin`, `… | nom args` | les *feeds* `==>` sont ce qui s'en rapproche le plus : `@a ==> map(…) ==> my @b` |
| `$?` pipefail, `@?` par étape | — |

En Raku, `|` au début d'un pipeline serait une jonction. rak garde le sens de jonction
partout où un pipeline ne commence pas ([12.5](#125-quand--est-un-tube)).

### Chapitre 13 : les cibles URL

| rak | Raku |
|---|---|
| `<url` | un module comme `Cro::HTTP::Client` ou `HTTP::Tiny` |
| `INSTR >url`, `http MÉTHODE URL CORPS` | les mêmes modules |
| `~/.config/rak/http-headers.json` | — |

### Chapitre 15 : les scripts

Les scripts `.rak` sont des scripts Raku avec la syntaxe rak. `MAIN`, `@*ARGS`,
`try`/`CATCH`, `die`, `exit` et `note` viennent tous de Raku. Un fichier qui finit par
`.raku` ou `.rakumod` est du Raku pur, même lancé par `rak` : du code rak et du code Raku
peuvent donc cohabiter dans un même projet.

---

## Annexe B : les pièges

Les surprises que rencontrent la plupart des débutants, chacune avec son remède et
l'endroit où elle est expliquée.

**`say hello world` affiche `helloworld`.**
Les chaînes nues juxtaposées sont des arguments séparés, et `say` les joint sans rien
entre eux. Écrivez `say 'hello world'`, ou `say hello, ' ', world`.
([4.3](#43-chaînes--nues-et-entre-guillemets))

**`$x.exitcode`, `@a.end`, `%h.keys` n'appellent pas la méthode.**
Un point suivi d'un mot est un indice. Utilisez la flèche pour une méthode sans
argument : `$?->exitcode`, `@a->end`, `%h->keys`. Avec des arguments, le point appelle :
`.split(',')`. ([9.5](#95-indices-et-méthodes))

**`.5` n'est pas un demi.**
Un point suivi d'un nombre indice le topique. Écrivez `0.5`.
([9.3](#93-partir-du-topique))

**`%h.$k` est une erreur.**
rak ne peut pas savoir si `$k` contient une clé ou un nom de méthode. Écrivez `%h."$k"`,
`%h.~k`, ou `%h->$k` pour une méthode. ([9.4](#94-des-pas-contenus-dans-des-variables))

**`%h.2024` dit « Index out of range ».**
Un nombre après un point est une position. Pour une clé faite de chiffres,
mettez-la entre apostrophes : `%h.'2024'`. ([9.1](#91-un-pas-à-la-fois))

**`[ { a => 1 } ]` n'est pas un tableau contenant un hachage.**
Un hachage seul entre crochets est aplati en ses paires. Ajoutez une virgule finale :
`[ { a => 1 }, ]`. ([8.4](#84-construire-teamjson))

**`<a b>` entre crochets est mal analysé.**
Écrivez `['a', 'b']`. ([8.4](#84-construire-teamjson))

**`for %team.people { … }` ne fait qu'un tour.**
Les valeurs à l'intérieur des structures sont itémisées. Écrivez
`for %team.people->list { … }`. De même pour `my @p = %team.people->list`.
([10.5](#105-des-boîtes-dans-des-boîtes--litémisation))

**Modifier une copie modifie l'original.**
L'affectation copie un seul niveau. Les tableaux et hachages imbriqués restent partagés.
Utilisez `deep-copy` ou un aller-retour JSON. ([10.3](#103-la-surprise--les-copies-sont-superficielles))

**`my ~t := ~s` échoue.**
Les variables natives ne peuvent pas être liées. Affectez plutôt.
([10.8](#108-les-variables-natives-ne-se-partagent-pas))

**`my #n = 2.7` et `my #n = 'abc'` échouent.**
Une variable `#` ne contient que des nombres entiers. Utilisez `$` pour les nombres
décimaux, `->Int` pour retirer la partie décimale. ([7.3](#73-les-sigils-propres-à-rak---et-))

**`#count` est devenu une variable alors que vous vouliez un commentaire.**
Un commentaire commence par `#` suivi d'une espace. ([7.6](#76-types-et-commentaires))

**`$a >2` ou `$a <5` ne compare pas.**
Une redirection touche sa cible ; une comparaison est espacée. Écrivez `$a > 2`,
`$a < 5`. ([11.7](#117-lespacement-fait-partie-de-la-syntaxe))

**`say … >fichier.json` échoue avec « invalid JSON ».**
Mode texte : le texte affiché doit être du JSON. Retirez le `say` pour enregistrer la
valeur. ([11.5](#115-mode-valeur-et-mode-texte))

**`>>fichier.json` est refusé.**
Un JSON contient une seule valeur. Utilisez un fichier `.jsonl` pour ajouter des
enregistrements. ([11.4](#114-formats))

**`my %h <list.json` échoue.**
Le sigil doit convenir au contenu : `@` pour un tableau, `%` pour un objet, `$` pour
n'importe quoi. ([11.4](#114-formats))

**`@names | ^sort` ne fait pas de tube.**
Un pipeline commence par une commande, un chargement ou un chemin pointé en tête. Fixez
le topique et écrivez `.[] | ^sort`. ([12.5](#125-quand--est-un-tube))

**`$?` dit que le pipeline a échoué alors que la dernière commande a réussi.**
`$?` est le premier échec du pipeline. `@?` contient le statut de chaque étape.
([12.8](#128-statut-de-sortie-dun-pipeline))

**`"%p.name"` n'interpole pas le nom.**
Entre guillemets doubles, mettez un chemin pointé entre accolades : `"{%p.name}"`.
([15.7](#157-un-second-exemple--starsrak))

**Une routine et un programme portent le même nom ; c'est la routine qui s'exécute.**
`type NOM` montre les deux. Utilisez `^nom` pour le programme.
([5.3](#53-qui-lemporte-pour-un-nom))

**`my @all <url` n'en finit pas.**
`@` récupère toutes les pages. Utilisez `$` et `->head` pour explorer.
([13.8](#138-pages))

**Une valeur s'affiche dans irak mais pas dans votre script.**
Les scripts ne montrent rien d'eux-mêmes. Ajoutez `say`. ([15.1](#151-les-scripts))

**Utiliser une valeur peut-être absente donne un avertissement « uninitialized value ».**
Un chemin manquant est indéfini. Protégez-vous avec `//`, ou testez avec `:exists`.
([9.9](#99-chemins-manquants))

---

## Annexe C : mini-glossaire

Chaque terme est suivi, entre parenthèses, de son équivalent anglais, que vous
rencontrerez dans la documentation de Raku.

**API** : un service fait pour les programmes, qui répond généralement aux requêtes HTTP
par du JSON. ([13.1](#131-clients-serveurs-et-url))

**argument** (*argument*) : une valeur donnée à une routine ou à un programme quand on
l'appelle.

**tableau** (*array*) : une liste ordonnée de valeurs, contenue dans une variable `@`.
([8.1](#81-tableaux))

**liaison** (*binding*, `:=`) : faire qu'un nom désigne un conteneur existant, au lieu de
copier une valeur dans un nouveau. ([10.2](#102-la-liaison--un-second-nom-pour-la-même-chose))

**bloc** (*block*) : du code entre accolades `{ }`. Il a sa propre portée.

**corps** (*body*, d'une requête ou réponse HTTP) : le contenu, par opposition aux
en-têtes.

**conteneur** (*container*) : la boîte qui contient une valeur dans une variable `$`,
`@` ou `%`, ou à l'intérieur d'une structure. Les variables natives n'en ont pas.

**répertoire courant** (*current directory*) : le répertoire d'où partent les chemins
relatifs ; `$*CWD`, `pwd`.

**copie profonde** (*deep copy*) : une copie de chaque niveau d'une structure imbriquée.
Comparez avec **copie superficielle**. ([10.4](#104-copier-exprès))

**indice pointé** (*dotty subscript*) : `.clé` ou `.position` après une valeur, qui y
lit un pas plus loin. ([9.1](#91-un-pas-à-la-fois))

**variable dynamique** (*dynamic variable*) : une variable avec `*` après son sigil,
fournie par rak : `$*CWD`, `%*ENV`, `@*ARGS`.

**élément** (*element*) : une valeur d'un tableau ou d'une liste.

**variable d'environnement** (*environment variable*) : une chaîne nommée qu'un processus
hérite de son parent : `HOME`, `PATH`. Se lit avec `%*ENV`.
([3.2](#32-ce-que-porte-chaque-processus))

**statut de sortie** (*exit status*) : le nombre que renvoie un processus quand il se
termine ; 0 en cas de succès. Dans `$?`.

**format** (*format*) : comment les valeurs sont transformées en octets et inversement :
JSON, JSON Lines, texte. Choisi par l'extension ou par `Content-Type`.
([11.4](#114-formats))

**hachage** (*hash*) : une table de clés et de valeurs, contenue dans une variable `%`.
([8.2](#82-hachages))

**en-tête** (*header*, HTTP) : un fait étiqueté envoyé avec une requête ou une réponse,
comme `Content-Type`.

**indice** (*index*) : la position d'un élément dans un tableau, comptée à partir de 0.

**irak** : l'invite interactive de rak, le REPL.

**itémisation** (*itemization*) : mettre une liste dans une seule boîte pour qu'elle
compte comme un seul élément. ([10.5](#105-des-boîtes-dans-des-boîtes--litémisation))

**JSON**, **JSON Lines** : des formats texte pour les données.
([8.7](#87-json-la-langue-commune-des-données))

**juxtaposition** (*juxtaposition*) : écrire des chaînes nues côte à côte, comme
arguments séparés : `f foo bar`.

**clé** (*key*) : le nom qui mène à une valeur dans un hachage.

**paresseux** (*lazy*) : calculé seulement quand c'est nécessaire. Les pipelines et les
chargements d'URL paginés sont paresseux.

**chargement** (*load*) : `CIBLE <source` : lire et décoder un fichier ou une URL dans
une variable ou le topique. ([11.3](#113-le-chargement--un-fichier-dans-une-variable))

**méthode** (*method*) : quelque chose que sait faire une valeur, appelé avec `->nom` ou
`.nom(…)`.

**chaîne nue** (*naked string*) : un mot écrit sans guillemets, utilisé comme chaîne.
([4.3](#43-chaînes--nues-et-entre-guillemets))

**natif** (*native*) : une valeur stockée directement, sans conteneur : les variables `~`
et `#`. ([7.3](#73-les-sigils-propres-à-rak---et-))

**chemin** (*path*, données) : une chaîne d'indices pointés : `.people.0.name`.
**chemin** (*path*, fichier) : une suite de noms de répertoires : `/home/ada/notes.txt`.

**pipeline** (*pipeline*) : des étapes reliées par `|`, chacune alimentant la suivante.
([chapitre 12](#12-pipelines))

**bloc pointu** (*pointy block*) : un bloc avec des paramètres : `-> $x { … }`.

**processus** (*process*) : un programme en cours d'exécution, avec sa propre mémoire,
son identifiant et ses flux standard. ([chapitre 3](#3-processus))

**intervalle** (*range*) : `1..5`, les nombres de 1 à 5.

**récursivité** (*recursion*) : une routine qui s'appelle elle-même sur les plus petites
parties d'un problème. ([9.8](#98-profondeur-inconnue--tout-parcourir))

**redirection** (*redirection*) : envoyer l'entrée ou la sortie d'une instruction vers un
fichier ou une URL au lieu du terminal. ([chapitre 11](#11-redirection-et-formats))

**REPL** : *Read-Eval-Print Loop*, boucle lire-évaluer-afficher, une invite interactive
comme irak.

**routine** (*routine*) : un morceau de code nommé, déclaré avec `sub`, appelé avec des
arguments.

**portée** (*scope*) : la partie du code où un nom est valide.

**script** (*script*) : un fichier de code rak exécuté du début à la fin.
([chapitre 15](#15-dirak-à-un-script-rak))

**copie superficielle** (*shallow copy*) : une copie du premier niveau d'une structure ;
les parties imbriquées sont partagées. ([10.3](#103-la-surprise--les-copies-sont-superficielles))

**shebang** : la première ligne `#!` d'un script, qui nomme le programme qui l'exécute.

**sigil** (*sigil*) : le symbole au début du nom d'une variable : `$ @ % & ~ #`.
([chapitre 7](#7-variables-et-sigils))

**signal** (*signal*) : un message que le système envoie à un processus, comme `SIGINT`
(Ctrl-C) ou `SIGPIPE`. ([3.7](#37-arrêter-un-processus))

**glisser** (*slip*, `|`) : déverser les éléments d'une liste dans la liste qui
l'entoure.

**smartmatch** (`~~`) : tester une valeur contre un type, un motif ou une valeur.

**étape** (*stage*) : une partie d'un pipeline : un programme, ou une méthode, un chemin,
un bloc ou une routine rak.

**entrée, sortie, erreur standard** (*standard input, output, error*) : les trois flux
avec lesquels démarre tout processus. En rak : `$*IN`, `$*OUT`, `$*ERR`.

**code de statut** (*status code*, HTTP) : le nombre qui dit comment s'est passée une
requête : 200, 404, 500.

**soumission** (*submission*) : ce que vous tapez à l'invite d'irak et envoyez avec
Entrée.

**topique** (*topic*, `$_`) : la valeur courante : dans irak, la valeur de la soumission
précédente ; dans une boucle, l'élément courant. ([chapitre 6](#6-le-topique-et-lhistorique))

**indéfini** (*undefined*) : un conteneur `$` vide, affiché `(Any)`.
([7.5](#75-valeurs-manquantes))

**URL** : l'adresse de quelque chose sur le web. ([13.1](#131-clients-serveurs-et-url))

**mode valeur**, **mode texte** (*value mode*, *text mode*) : selon qu'une redirection
écrit la valeur de l'instruction ou son texte affiché.
([11.5](#115-mode-valeur-et-mode-texte))

**expression whatever** (*whatever expression*) : `*.name`, `* + 1` : une courte routine
anonyme, où `*` tient lieu de son argument. ([9.7](#97-transformer-des-listes))
