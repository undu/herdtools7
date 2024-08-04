  $ cat >print.asl <<EOF
  > constant msg = "old pond\\nfrog leaps in\\nwater's sound";
  > func main () => integer begin print(msg); return 0; end
  > EOF
  $ aslref print.asl
  old pond
  frog leaps in
  water's sound
  $ cat >print.asl <<EOF
  > constant msg = "old pond\\n\\tfrog\\tleaps in\\nwater's\\tsound";
  > func main () => integer begin print(msg); return 0; end
  > EOF
  $ aslref print.asl
  old pond
  	frog	leaps in
  water's	sound
  $ cat >print.asl <<EOF
  > constant msg = "Check out this haiku:\\n\\t\\"old pond\\n\\tfrog leaps in\\n\\twater's sound\\"";
  > func main () => integer begin print(msg); return 0; end
  > EOF
  $ aslref print.asl
  Check out this haiku:
  	"old pond
  	frog leaps in
  	water's sound"
  $ cat >print.asl <<EOF
  > constant msg = "Something with \\\\ backslashes.";
  > func main () => integer begin print(msg); return 0; end
  > EOF
  $ aslref print.asl
  Something with \ backslashes.
  $ cat >print.asl <<EOF
  > constant msg = "Something with \\p bad characters.";
  > func main () => integer begin print(msg); return 0; end
  > EOF
  $ aslref print.asl
  File print.asl, line 1, characters 32 to 33:
  ASL Error: Unknown symbol.
  [1]
  $ cat >print.asl <<EOF
  > constant msg = "Some unterminated string;
  > func main () => integer begin print(msg); return 0; end
  $ aslref print.asl
  File print.asl, line 3, character 0:
  ASL Error: Unknown symbol.
  [1]

C-Style comments
  $ cat >comments.asl <<EOF
  > func /* this is a /* test */ main () => integer
  > begin /*
  > let's try a multi-line comment /*
  > which finishes here */ constant msg = "/* a comment inside a string? */"; /* another comment
  > that finishes somewhere **/ print (msg); // but not here! */
  > return 0; /* oh a new one */
  > // /* when in a commented line, it doesn't count!
  > end
  > EOF

  $ aslref comments.asl
  /* a comment inside a string? */

  $ cat >comments.asl <<EOF
  > /*
  >  
  >  
  >  
  > */
  > 
  > let foo = "sigjrshgrsas
  > kgjrgsoirjggsr
  > fsoirjgrsig";
  > 
  > let a = b;
  > EOF

  $ aslref comments.asl
  File comments.asl, line 11, characters 8 to 9:
  ASL Error: Undefined identifier: 'b'
  [1]

