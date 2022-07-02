%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

extern int yylex();
extern FILE *yyin;
extern FILE *yyout;
%}

%union{
 float f;
}

%token <f> NUM
%type <f> ADDSUB MULTDIV EXPOROOT FUNCTION ADVANCEDOPERATION BASICOPERATION

%%

S : ADDSUB							{
								    fprintf(yyout, "%f\n", $1);
								}
  ;
  
ADDSUB : ADDSUB '+' MULTDIV					{$$ = $1 + $3;}
       | ADDSUB '-' MULTDIV					{$$ = $1 - $3;}
       | MULTDIV						{$$ = $1;}
       ;
  
MULTDIV : MULTDIV '*' EXPOROOT					{$$ = $1 * $3;}
        | MULTDIV '/' EXPOROOT					{$$ = $1 / $3;}
        | EXPOROOT						{$$ = $1;}
        ;
  
EXPOROOT : EXPOROOT '^' FUNCTION				{$$ = powf($1, $3);}
         | FUNCTION						{$$ = $1;}
         ;
  
FUNCTION : 'c' FUNCTION						{$$ = cosf($2);}
	 | 's' FUNCTION       					{$$ = sinf($2);}
         | 'l' FUNCTION						{$$ = logf($2);}
         | ADVANCEDOPERATION					{$$ = $1;}
         ;
         
ADVANCEDOPERATION : 'r' '(' ADDSUB ',' ADVANCEDOPERATION ')'	{$$ = roundf($3 * powf(10, $5))/powf(10, $5);}
		  | BASICOPERATION				{$$ = $1;}	
		  ;
  
BASICOPERATION : '(' ADDSUB ')'					{$$ = $2;}
               | '-' BASICOPERATION				{$$ = -$2;}
               | NUM						{$$ = $1;}
               ;

%%

void yyerror(char *msg){
  fprintf(stderr, "%s\n", msg);
  exit(1);
}

int main(int argc, char** argv){
  if(argc == 3){
    yyin = fopen(argv[1], "r");
    yyout = fopen(argv[2], "w");
  }
  yyparse();
  fclose(yyin);
  fclose(yyout);
  return 0;
}
