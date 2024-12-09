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
my ($title0, $title1, $title2, $up, $prev, $next, @cards, @paragraphs);

# Lit le fichier d'entrée
open my $fh, '<', $input_file or die "Impossible d'ouvrir le fichier '$input_file': $!\n";

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
    elsif ($line =~ /^UP:\s*(.*)/) {
        $up = $1 || '';
    }
    elsif ($line =~ /^PREV:\s*(.*)/) {
        $prev = $1 || '';
    }
    elsif ($line =~ /^NEXT:\s*(.*)/) {
        $next = $1 || '';
    }
    elsif ($line =~ /^PARAGRAPH:\s*(.+)/) {
        my $paragraph = $1;
        $paragraph =~ s/\*\*(.*?)\*\*/<strong>$1<\/strong>/g;
        
        push @paragraphs, $paragraph ;
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
            } elsif ($card_line =~ /^\s*DESCRIPTION:\s*(.+)/) {
                $card{description} = $1;
            } elsif ($card_line =~ /^\s*IMAGE:\s*(.+)/) {
                $card{image} = $1;
            }
        }
        push @cards, \%card;
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
    <title>$title0</title>
    <link rel="stylesheet" href="$css_file">
</head>
<body>

<!-- Barre de navigation avec les boutons en rangée -->
<div class="top-navigation">
	<a href="$up" class="button small-button" title="Monter dans l'arborescence" $up_disabled>&#x2191; Page supérieure</a>
	<a href="$prev" class="button small-button" title="Retourner à la page précédente" $prev_disabled>&#x2190; Page précédente</a>
	<a href="$next" class="button small-button" title="Accéder à la page suivante" $next_disabled>&#x2192; Page suivante</a>
</div>

<div class="container">
    <h1>$title1</h1>
    <h2>$title2</h2>

HTML


foreach my $paragraph (@paragraphs) {
	print $out <<"HTML";
		<p class="paragraph">
			$paragraph 
		</p>\n
HTML
}

print $out "    <div class='card-grid'>\n" ;

# Génère chaque carte
foreach my $card (@cards) {
    my $cardTitle1    = $card->{title1};
    my $cardTitle2    = $card->{title2};
    my $image         = $card->{image};
    my $link          = $card->{link};
    my $description   = $card->{description};


    print $out "        <div class='card'>\n" ;
    
	if ( $link ) {
		print $out "<a href='$link' class='card-link'>\n" ;
	}
    
    
    if ($image) {
    	print $out "            <img src='$image' alt='' class='card-image'>\n" ;
    	}
    
    print $out "		    <div class='card-content'>\n" ;
    print $out "			    <h3 class='cardTitle1'> $cardTitle1 </h3>\n" ;
	if ( $cardTitle2 ) {
	    print $out "			    <p class='cardTitle2'> $cardTitle2 </p>\n" ;
		}
	print $out "                <p class='card-text'> $description </p>\n" ;

	print $out "		    </div>\n" ;
	if ( $link ) {
		print $out "</a>\n" ;
	}


    print $out "        </div>\n\n" ;

}

# Ferme la section des cartes
print $out <<"HTML";
    </div>
HTML


print $out <<"HTML";
</div>
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