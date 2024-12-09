#!/usr/bin/perl
use strict;
use warnings;
use File::Path qw(make_path);

# Vérification du nombre d'arguments
if (@ARGV != 2) {
    die "Usage: perl script.pl <chemin_fichier_avec_suffixe_txt> <css_fichier__sans_extension>\n";
}

my $input_file = $ARGV[0];
my $css_basename = $ARGV[1];  # Nom de base du fichier CSS sans extension

# Vérification que le fichier d'entrée contient le suffixe .txt
if ($input_file !~ /\.txt$/) {
    die "Erreur : le fichier d'entrée doit contenir le suffixe '.txt'.\n";
}

# Retire le chemin pour ne garder que le nom du fichier sans extension
(my $base_file = $input_file) =~ s|.*/||;  # Retire le chemin pour garder le nom
$base_file =~ s|\.txt$||;  # Retire l'extension .txt

# Récupérer le chemin sans le nom de fichier et préparer le chemin de sortie
(my $path_only = $input_file) =~ s|[^/]+$||;  # Chemin sans le nom de fichier
$path_only =~ s|data|html|g;  # Remplace 'data' par 'html'

my $output_file = "$path_only$base_file.html";  # Définir le chemin de sortie

# Calculer le nombre de sous-dossiers pour déterminer la profondeur
my $depth = () = $path_only =~ m|/|g;
my $css_path = "./" x $depth;  # Génère le chemin relatif pour le CSS

# Vérifier l'existence du dossier de sortie, le créer si nécessaire
unless (-d "./$path_only") {
    make_path("./$path_only") or die "Impossible de créer le dossier '$path_only' : $!";
}

# Chemin complet vers le fichier CSS
my $css_file = "${css_path}css/$css_basename.css";


# Lit le fichier d'entrée
open my $fh, '<', $input_file or die "Impossible d'ouvrir le fichier '$input_file': $!\n";

# Variables pour stocker les informations extraites du fichier texte
my ($title0, $title1, $title2, @images, @cards);

# Parcourt chaque ligne du fichier
while (my $line = <$fh>) {
    chomp $line;

    # Identifie et stocke les titres
    if ($line =~ /^TITLE0:\s*(.+)/) {
        $title0 = $1;
    }
    elsif ($line =~ /^TITLE1:\s*(.+)/) {
        $title1 = $1;
    }
    elsif ($line =~ /^TITLE2:\s*(.+)/) {
        $title2 = $1;
    }
    # Identifie les images et les ajoute au tableau
    elsif ($line =~ /^IMAGE:\s*(.+)/) {
        push @images, $1;
    }
    # Identifie les informations des cartes
    elsif ($line =~ /^CARD:/) {
        my %card;
        while (my $card_line = <$fh>) {
            chomp $card_line;
            last if $card_line eq '';

            if ($card_line =~ /^\s*TITLE1:\s*(.+)/) {
                $card{title1} = $1;
            } elsif ($card_line =~ /^\s*TITLE2:\s*(.+)/) {
                $card{title2} = $1;
            } elsif ($card_line =~ /^\s*LINK:\s*(.+)/) {
                $card{link} = $1;
            }
        }
        push @cards, \%card;
    }
}

close $fh;

# Génère le fichier HTML
open my $out, '>', $output_file or die "Impossible de créer le fichier '$output_file': $!\n";

# Écrit le contenu HTML
print $out <<"HTML";
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title0</title>
    <link rel="stylesheet" href="$css_file">
</head>
<body>

<div class="container">
    <h1>$title1</h1>
    <h2>$title2</h2>

    <!-- Grille des cards -->
    <div class="card-grid">
HTML

# Génère chaque carte
foreach my $card (@cards) {
    my $cardTitle1 = $card->{title1};
    my $cardTitle2 = $card->{title2};
    my $link       = $card->{link};

    print $out <<"CARD";
        <div class="card">
            <a href="$link">$cardTitle1<br>
                <span class="subtitle">$cardTitle2</span>
            </a>
        </div>
CARD
}

# Ferme la section de la grille des cartes
print $out "\t</div> <!-- Fermeture de la grille de cartes -->\n";

# Ajoute les images si elles sont définies
if (@images) {
    print $out "\t<div class='illustration'>\n";
    foreach my $image (@images) {
        print $out "\t\t<img src='$image' alt='Illustration du cours'>\n";
    }
    print $out "\t</div>\n";
}

print $out "</div>\n\n";

# Continue avec le reste du HTML
print $out <<"HTML";
<footer class="footer">
    <p><strong>RocksandWalk</strong> &copy; <span id="current-year"></span> | Régis THIÉRY</p>
</footer>

<script>
    // Script pour afficher automatiquement l'année en cours
    document.getElementById("current-year").textContent = new Date().getFullYear();
</script>

</body>
</html>
HTML

close $out;

print "Processed $output_file\n";
