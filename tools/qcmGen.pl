#!/usr/bin/perl
use strict;
use warnings;
use File::Path qw(make_path);
use List::Util 'shuffle';

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



my ($title0, $title1, $title2) = ('', '', '');
my ($up, $prev, $next) = ('', '', '');
my @questions ;
my @videos ;
my @images ;
my @paragraphs ;
my $noShuffleFlag = 0 ;


# Ouvrir le fichier d'entrée
open(my $fh, '<', $input_file) or die "Impossible d'ouvrir '$input_file' : $!";



# Traiter chaque question
my $question_number = 1;
my %correct_answers;

while (my $line = <$fh>) {
    chomp($line);
    
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
    elsif ($line =~ /NOSHUFFLE/ ) {
    	$noShuffleFlag = 1 ;
    }
    elsif ($line =~ /^P:\s*(.+)/) {
        my $paragraph = $1;
        $paragraph =~ s/\*\*(.*?)\*\*/<strong>$1<\/strong>/g;
        
        push @paragraphs, $paragraph ;
    }
    elsif ($line =~ /^V:\s*(.+)/) {
        my $video = $1;
        push @videos, $video ;
    }
 	elsif ($line =~ /^I:\s*([^\s&]+)\s*&&\s*(.*)/) {
		my %image = ( path => $1, caption => $2 );
		push(@images, \%image);
	}
   
    
    
    
    elsif ($line =~ /^Q:\s*(.+)/) {
		my %question;

		$question{text} = $1 ;


        my @answers;
        my $comment;
        my @images ;
        my @videos;
        my $letter = 'A';


        while (my $answer_line = <$fh> ) {
			chomp($answer_line);
			last if $answer_line =~ /^\s*$/;

			if ($answer_line =~ /^\tG:\s*(.*)/) {
				push @answers, { text => $1, is_correct => 1, letter => $letter };
				$letter++;
			} elsif ($answer_line =~ /^\tB:\s*(.*)/) {
				push @answers, { text => $1, is_correct => 0, letter => $letter };
				$letter++;
			} elsif ($answer_line =~ /^\tC:\s*(.*)/) {
				$comment = $1;
				$comment =~ s/\*\*(.*?)\*\*/<strong>$1<\/strong>/g;
				
				while (my $next_line = <$fh>) {
		            chomp($next_line);
		            last if $next_line =~ /^\s*$/;  # Fin du commentaire

        		    # Ajoute la ligne suivante au commentaire
		            $next_line =~ s/\*\*(.*?)\*\*/<strong>$1<\/strong>/g;
		            $comment .= " " . $next_line;
			        }				
				
                last ;
				
			} elsif ($answer_line =~ /^\tI:\s*([^\s&]+)\s*&&\s*(.*)/) {
			    my %image = ( path => $1, caption => $2 );
			    push(@images, \%image);
			}
			elsif ($answer_line =~ /^\tV:\s*(.*)/) {
				my $video_path = $1;
			    push(@videos, $video_path);
			}
		}

		my @new_answers = shuffle @answers;
		$question{number} = $question_number ;
		$question{videos} = \@videos ;
		$question{answers} = \@new_answers ;
		$question{comment} = $comment ;
		$question{images} = \@images ;


        push @questions, \%question;

        $question_number++;
    }
}

if ($noShuffleFlag == 0 ) {
	@questions = shuffle(@questions);
}

# Ouvrir le fichier de sortie HTML
open(my $out, '>', $output_file) or die "Impossible d'ouvrir '$output_file' : $!";

my $up_disabled = $up ? "" : 'disabled';
my $prev_disabled = $prev ? "" : 'disabled';
my $next_disabled = $next ? "" : 'disabled';

print $out <<EOF;
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title0</title>
    <link rel="stylesheet" href="$css_file">
</head>
<body>

<div class="nav-buttons">
    <a href="$up"   class="nav-button"  $up_disabled>Retour</a>
    <a href="$prev" class="nav-button"  $prev_disabled>Page précédente</a>
    <a href="$next" class="nav-button"  $next_disabled>Page suivante</a>
</div>

<div class="container">
    <h1>$title1</h1>
    <h2>$title2</h2>
EOF
    

foreach my $paragraph (@paragraphs) {
	print $out <<"HTML";
		<p class="paragraph">
			$paragraph 
		</p>\n
HTML
}

foreach my $image (@images) {
	my $image_path = $image->{path};
	my $caption = $image->{caption};
	print $out qq(\t\t\t<div class="image-container">\n);
	print $out qq(\t\t\t\t<img class="question-image" src="$image_path" alt="Image pour la question $question_number">\n);
	print $out qq(\t\t\t\t<p class="image-caption">$caption</p>\n) if $caption;  # Affiche la légende si elle existe
	print $out qq(\t\t\t</div>\n);
}

foreach my $video_path (@videos) {
	print $out qq (
	<div class="video-container">
		<video class="question-video"  controls>
			<source src="$video_path" type="video/mp4">
			Votre navigateur ne supporte pas la lecture de cette vidéo.
		</video>
	</div>
	) ;
}
    
    
    
print $out <<EOF;
    <form id="qcm-form">
EOF

my $questionIndex = 1 ;
foreach my $question (@questions) {
		my $question_number = $question->{number} ;
	    my $question_text = $question->{text};
		my @videos = @{ $question->{videos} };
	    my @answers = @{ $question->{answers} };
		my $comment = $question->{comment} ;
	    my @images = @{ $question->{images} };


        print $out <<EOF;
        <div class="question-box" id="q$question_number-box">
            <div class="question">$questionIndex. $question_text</div>
EOF



		if (@images) {
		    foreach my $image (@images) {
    		    my $image_path = $image->{path};
		        my $caption = $image->{caption};
    		    print $out qq(\t\t\t<div class="image-container">\n);
		        print $out qq(\t\t\t\t<img class="question-image" src="$image_path" alt="Image pour la question $question_number" onclick="openModal(this);">\n);
	    	    print $out qq(\t\t\t\t<p class="image-caption">$caption</p>\n) if $caption;  # Affiche la légende si elle existe
		        print $out qq(\t\t\t</div>\n);

    		    print $out qq(\t\t\t<div id="imageModal" class="modal">\n);
    		    print $out qq(\t\t\t    <span class="close" onclick="closeModal()">&times;</span>\n);
    		    print $out qq(\t\t\t    <img class="modal-content" id="modalImage">\n);
    		    print $out qq(\t\t\t</div>\n);
	    	}
	    	@images = (); 
		}

        
		if (@videos) {
            foreach my $video_path (@videos) {
    			print $out qq (	    		<div class="video-container">
    	        	<video class="question-video"  controls>
        	        	<source src="$video_path" type="video/mp4">
	                	Votre navigateur ne supporte pas la lecture de cette vidéo.
		            </video>
			    </div>\n) ;
            }
		}	
		
        
        print $out  "\t\t\t<div class='options'>\n" ;

        # Détecter si plusieurs réponses correctes existent
        my $input_type = scalar(grep { $_->{is_correct} } @answers) > 1 ? "checkbox" : "radio";

        foreach my $index (0 .. $#answers) {
            my $answer = $answers[$index];
            my $answer_letter = chr(65 + $index);
            my $answerLetter = $answer->{letter} ;

            print $out <<EOF;
                <label><input type="$input_type" class="checkbox-margin" name="q$question_number" value="$answerLetter"> $answer_letter) $answer->{text} </label>
EOF

        }


        print $out "\t\t\t</div>\n";
        
        print $out "\t\t\t<p class='feedback' style='display:none;'></p>\n";
        print $out "\t\t\t<p class='correct-answer' style='display:none;'></p>\n";

        if ($comment) {
            print $out "\t\t\t<div class='comment' style='display:none;'><strong>Commentaire:</strong> $comment</div>\n";
        }
        
        print $out "\t\t</div>\n";
        $questionIndex ++ ;
	}



# Ajouter le JavaScript de correction
print $out <<'EOF';

        <div class="buttons">
            <button type="button" onclick="evaluateQCM()">Corriger</button>
            <button type="button" onclick="resetTest()">Recommencer</button>
        </div>

    </form>
    <p id="result"></p>
</div>

<footer>
    GeoCool - @ <script> document.write(new Date().getFullYear())</script> - Régis THIÉRY
</footer>

<script>
    function evaluateQCM() {
        const correctAnswers = {
EOF



foreach my $question (@questions) {

    my @answers = @{ $question->{answers} }; # Utiliser @{...} pour extraire les éléments d'une référence de tableau
    my @correct_options = map { $_->{letter} } grep { $_->{is_correct} == 1 } @answers;

    print $out qq(            "q$question->{number}": [") . join('", "', @correct_options) . qq("],\n);
}




print $out <<'EOF';
        };
        

        let score = 0;

        function generateFeedbackText(goodAnswers, goodCount, questionBox) {
            // Fonction utilitaire pour récupérer les 3 premières lettres d'une réponse
    
            function getAnswerLabel(value) {
                const label = questionBox.querySelector(`input[value="${value}"]`).parentNode;
                return label.textContent.trim().slice(0, 3); // Extrait les 3 premières lettres (ex: "A)")
            }

            if (goodAnswers.length === 0) {
                return "Pas de bonne réponse !";
            }

            const formattedAnswers = goodAnswers.map(answer => getAnswerLabel(answer));

            if (goodAnswers.length === 1) {
                return `${formattedAnswers[0]} est ${goodCount === 1 ? "la" : "une"} bonne réponse.`;
            }

            if (goodAnswers.length > 1) {
                return `${formattedAnswers.slice(0, -1).join(", ")} et ${formattedAnswers[formattedAnswers.length - 1]} sont de bonnes réponses.`;
            }

            return "";
            }


        for (let question in correctAnswers) {
            const selected = Array.from(document.querySelectorAll(`input[name="${question}"]:checked`)).map(e => e.value);
            const questionBox = document.getElementById(`${question}-box`);
            const correctOptions = correctAnswers[question];
            
            const goodAnswers = selected.filter(val => correctOptions.includes(val));
            let feedback = generateFeedbackText(goodAnswers, correctOptions.length, questionBox);

            let isCorrect = selected.length === correctOptions.length && correctOptions.every(option => selected.includes(option));
            questionBox.classList.toggle("correct", isCorrect);
            questionBox.classList.toggle("incorrect", !isCorrect);

            selected.forEach(val => {
                const optionLabel = questionBox.querySelector(`input[value="${val}"]`).parentNode;
                if (correctOptions.includes(val)) {
                    optionLabel.style.fontWeight = "bold";
                } else {
                    optionLabel.classList.add("strikethrough");
                }
            });

            correctOptions.forEach(val => {
                const correctOptionLabel = questionBox.querySelector(`input[value="${val}"]`).parentNode;
                if (!selected.includes(val)) {
                    correctOptionLabel.style.fontWeight = "bold";
                }
            });

            const correctAnswerLabel = questionBox.querySelector('.correct-answer');
            const feedbackLabel = questionBox.querySelector('.feedback');
            const commentBox = questionBox.querySelector('.comment');
            if (feedbackLabel) {
                feedbackLabel.style.display = 'block';
                feedbackLabel.innerHTML = feedback;
            }
            if (commentBox) {
                commentBox.style.display = 'block';
            }
           
            // Mappage des bonnes réponses avec les lettres (A, B, C, D)
            const correctAnswerLabels = correctOptions.map(val => {
                const label = questionBox.querySelector(`input[value="${val}"]`).parentNode;
                const text = label.textContent.trim();
                return `${text}`;
                });


            let correctAnswerText = correctOptions.length === 1 
                ? `Bonne réponse : ${correctAnswerLabels.join("; ")}`
                : `Bonnes réponses : ${correctAnswerLabels.join("; ")}`;
            
            correctAnswerLabel.innerHTML = correctAnswerText;
            correctAnswerLabel.style.display = 'block';

            if (isCorrect) score+=goodAnswers.length;
        }

        const totalValues = Object.values(correctAnswers).reduce((acc, curr) => acc + curr.length, 0);
        const result = document.getElementById("result");

        if (score === 0) {
            result.textContent = `Vous n'avez obtenu aucune bonne réponse sur ${totalValues}.`;
        } else if (score === 1) {
            result.textContent = `Vous avez obtenu 1 bonne réponse sur ${totalValues}.`;
        } else {
            result.textContent = `Vous avez obtenu ${score} bonnes réponses sur ${totalValues}.`;
        }
    }

    function resetTest() {
        window.location.reload();
    }

    function openModal(imgElement) {
        var modal = document.getElementById("imageModal");
        var modalImg = document.getElementById("modalImage");
        modal.style.display = "block";
        modalImg.src = imgElement.src;  // Utiliser l'image cliquée
    }

    function closeModal() {
        var modal = document.getElementById("imageModal");
        modal.style.display = "none";
    }

</script>




</body>
</html>
EOF

# Fermer les fichiers
close($fh);
close($out);

print "Processed '$output_file'\n";