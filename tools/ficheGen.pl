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

my $output_file = "./$path_only$base_file.html";  # Définir le chemin de sortie

# Calculer le nombre de sous-dossiers pour déterminer la profondeur
my $depth = () = $path_only =~ m|/|g;
$depth -=1 ;
my $css_path = "../" x $depth;  # Génère le chemin relatif pour le CSS

# Vérifier l'existence du dossier de sortie, le créer si nécessaire
unless (-d "./$path_only") {
    make_path("./$path_only") or die "Impossible de créer le dossier '$path_only' : $!";
}

# Chemin complet vers le fichier CSS
my $css_file = "${css_path}css/$css_basename.css";



# Variables pour stocker les informations extraites du fichier texte
my ($title0, $title1, $title2, $up, $prev, $next, $image, $summary, $level, $duration, @pdfs, @videos, $qcm);

# Lit le fichier d'entrée
open my $fh, '<', $input_file or die "Impossible d'ouvrir le fichier '$input_file': $!\n";

# Parcourt chaque ligne du fichier
while (my $line = <$fh>) {
    chomp $line;

    # Extraire les titres et liens de navigation
    if ($line =~ /^TITLE0:\s*(.+)/) {
        $title0 = $1;
    }
    elsif ($line =~ /^TITLE1:\s*(.+)/) {
        $title1 = $1;
    }
    elsif ($line =~ /^TITLE2:\s*(.+)/) {
        $title2 = $1;
    }
    elsif ($line =~ /^UP:\s*(.*)/) {
        $up = $1 || '';
    }
    elsif ($line =~ /^PREV:\s*(.*)/) {
        $prev = $1 || '';
    }
    elsif ($line =~ /^NEXT:\s*(.*)/) {
        $next = $1 || '';
    }
    elsif ($line =~ /^I:\s*(.*)/) {
        $image = $1;
    }
    elsif ($line =~ /^SUMMARY:\s*(.+)/) {
        $summary = $1;
    }
    elsif ($line =~ /^LEVEL:\s*(.+)/) {
        $level = $1;
    }
    elsif ($line =~ /^DURATION:\s*(.+)/) {
        $duration = $1;
    }
    elsif ($line =~ /^PDF:/) {
    	my %pdf;
        while (my $pdf_line = <$fh>) {
            chomp $pdf_line;
            last if $pdf_line eq '';
            if ($pdf_line =~ /^\s*TITLE:\s*(.+)/) {
                $pdf{title} = $1;
            }
            elsif ($pdf_line =~ /^\s*LINK:\s*(.+)/) {
                $pdf{link} = $1;
            }
        }
        push @pdfs, \%pdf;
    }
    elsif ($line =~ /^VIDEO:/) {
        my %video;
        while (my $video_line = <$fh>) {
            chomp $video_line;
            last if $video_line eq '';

            if ($video_line =~ /^\s*TITLE:\s*(.+)/) {
                $video{title} = $1;
            }
            elsif ($video_line =~ /^\s*LINK:\s*(.+)/) {
                $video{link} = $1;
            }
        }
        push @videos, \%video;
    }
    elsif ($line =~ /^QCM:/) {
        my %qcm_data;
        while (my $qcm_line = <$fh>) {
            chomp $qcm_line;
            last if $qcm_line eq '';

            if ($qcm_line =~ /^\s*TITLE:\s*(.+)/) {
                $qcm_data{title} = $1;
            }
            elsif ($qcm_line =~ /^\s*LINK:\s*(.+)/) {
                $qcm_data{link} = $1;
            }
        }
        $qcm = \%qcm_data;
    }
}

close $fh;

# Génère le fichier HTML
open my $out, '>', $output_file or die "Impossible de créer le fichier '$output_file': $!\n";

# Détermine les attributs pour désactiver les boutons si nécessaire
my $up_disabled = $up ? "" : 'disabled';
my $prev_disabled = $prev ? "" : 'disabled';
my $next_disabled = $next ? "" : 'disabled';

# Écrit le contenu HTML
print $out <<"HTML";
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title1</title>
    <link rel="stylesheet" href="$css_file">
</head>
<body>

<!-- Boutons de navigation en haut de la page -->
<div class="nav-buttons">
    <a href="$up" class="nav-button" $up_disabled>Retour</a>
    <a href="$prev" class="nav-button" $prev_disabled>Page précédente</a>
    <a href="$next" class="nav-button" $next_disabled>Page suivante</a>
</div>

<div class="fiche-container">
    <!-- Titre et illustration -->
    <div class="header">
        <h1>$title1</h1>
        <img src="$image" alt="Illustration sur $title1" class="fiche-illustration">
    </div>

    <!-- Informations principales -->
    <div class="info-section">
        <p><strong>Niveau :</strong> $level</p>
        <p><strong>Durée :</strong> $duration</p>
    </div>

    <!-- Sommaire descriptif -->
    <div class="sommaire">
        <h2>Sommaire</h2>
        <p>$summary</p>
    </div>

HTML

# Génère les liens PDF
if (@pdfs) {
	print $out "<h2 class='ficheItem'> Accéder aux documents PDF </h2>\n" ;
	foreach my $pdf (@pdfs) {
    	my $pdfTitle = $pdf->{title};
	    my $pdfLink = $pdf->{link};
    	print $out <<"PDF";
	    <div class="resources">
    	    <a href="$pdfLink" class="resource-link" target="_blank"> $pdfTitle</a>
	    </div>    
PDF
	}
}

# Génère les liens vidéo
if (@videos) {
	print $out "<h2 class='ficheItem'> Visionner les vidéos </h2>\n" ;
	foreach my $video (@videos) {
    	my $videoTitle = $video->{title};
	    my $videoLink = $video->{link};
    	print $out <<"VIDEO";
	    <div class="resources">
    	    <a href="$videoLink" class="resource-link" target="_blank">$videoTitle</a>
	    </div>    
VIDEO
	}
}

# Rubrique QCM
if ($qcm) {
    my $qcmTitle = $qcm->{title};
    my $qcmLink = $qcm->{link};
    print $out <<"QCM";
    <!-- Rubrique Auto-évaluation / QCM -->
    <div class="evaluation">
        <h2>Auto-évaluation / QCM</h2>
        <p>$qcmTitle</p>
        <a href="$qcmLink" class="resource-link" target="_blank">Commencer le QCM</a>
    </div>
QCM
}

# Ferme le HTML
print $out <<"HTML";
</div>

<!-- Bas de page -->
<footer class="footer">
    <p><strong>GeoCool</strong> &copy; <span id="current-year"></span> | Régis THIÉRY</p>
</footer>

<script>
    document.getElementById("current-year").textContent = new Date().getFullYear();
</script>

</body>
</html>
HTML

close $out;

print "Processed $output_file\n";
	