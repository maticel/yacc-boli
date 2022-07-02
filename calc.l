%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "y.tab.h"

FILE *funin;
FILE *funout;

float convert(char *str, int base);
char* getfilename(char funname, char* str);
void packfun(char *funbuildstr);
char* readfile(char *filename);
float runfun(char *funbuildstr);
%}

%option noyywrap

%%

[0-9]+(\.[0-9]+)?([eE][0-9+])?			{yylval.f = atof(yytext); return NUM;} // Decimal
(h)[0-9A-F]+					{yylval.f = convert(yytext, 16); return NUM;} // Hexadecimal
(b)[0-1]+					{yylval.f = convert(yytext, 2); return NUM;} // Binary
[-+()*/\^,]|(cos)|(sin)|(log)|(reduce)		{return yytext[0];}
PI						{yylval.f = M_PI; return NUM;}
(function)[ ][a-z](\([a-z](,[a-z])?\)=)([a-z]|[0-9]+(\.[0-9]+)?([eE][0-9+])?|(h)[0-9A-F]+|(b)[0-1]+|[-+()*/\^,]|[ ]|(cos)|(sin)|(log)|(reduce)|(function)[ ][a-z](\()(PI|[0-9]+(\.[0-9]+)?([eE][0-9+])?|(h)[0-9A-F]+|(b)[0-1]+)(\)))+(;)		{packfun(yytext);}
(function)[ ][a-z](\()(PI|[0-9]+(\.[0-9]+)?([eE][0-9+])?|(h)[0-9A-F]+|(b)[0-1]+)(,(PI|[0-9]+(\.[0-9]+)?([eE][0-9+])?|(h)[0-9A-F]+|(b)[0-1]+))?(\))	{yylval.f = runfun(yytext); return NUM;}
[ ]						{ ; }

%%

//Convert to decimal
float convert(char *str, int base){
  float ofloat = 0.0;
  int size = strlen(str);
  for (int i=1; i < size; ++i){
    ofloat += powf(base, size-1-i) * ( (str[i] - '0' < 10) ? (str[i] - '0') : (10 + (str[i] - 'A')) );
  }
  return ofloat;
}

char* getfilename(char funname, char* str){
  char *filename = malloc(32);
  sprintf(filename, "%s%c.fun", str, funname);
  return filename;
}

// Pack function to file
void packfun(char *funbuildstr){ // function a(x)=2+2;  
  char tmpfunstr[256]; 
  char *funstr;
  // Get function body
  strcpy(tmpfunstr, funbuildstr); 
  funstr = strtok(tmpfunstr, "=");
  funstr = strtok(NULL, ";");
  //Get function name
  char funname = funbuildstr[9];
  // Get variables
  char tmpvariables[256];
  char *variables;
  strcpy(tmpvariables, funbuildstr);
  variables = strtok(tmpvariables, "(");
  variables = strtok(NULL, ")=");
  char variable = funbuildstr[11];
  char *filename = getfilename(funname, "fun/");
  // Write function to file
  funout = fopen(filename, "w");
  fprintf(funout, "%s:%s", variables, funstr);
  fclose(funout);
}

// Read from file
char* readfile(char *filename){
  funin = fopen(filename, "r");
  char *buffer = NULL;
  size_t len;
  ssize_t bytes_read = getdelim(&buffer, &len, '\0', funin);
  if (bytes_read != -1){
  	return buffer;
  }
  exit(1);
}

// Unpack function from file and run it
float runfun(char *funbuildstr){
  float ofloat = 0.0;
  // Get function name
  char funname = funbuildstr[9];
  char *filename = getfilename(funname, "fun/");
  // Read function from file
  char *funexpresion = readfile(filename);
  // Get function from expresion
  char tmpfunction[256];
  char *function;
  strcpy(tmpfunction, funexpresion);
  function = strtok(tmpfunction, ":");
  function = strtok(NULL, ":");
  // Get value of variables
  char *valueofvariables;
  char tmpfunbuildstr[256];
  strcpy(tmpfunbuildstr, funbuildstr); 
  valueofvariables = strtok(tmpfunbuildstr, "(");
  valueofvariables = strtok(NULL, ")");
  // Get list of values
  char ** valuelist = NULL;
  char * workvalue = strtok(valueofvariables, ",");
  int n = 0,i;
  while(workvalue){
    valuelist = realloc(valuelist, sizeof (char*) * ++n);
    if (valuelist == NULL){
      exit (1);
    }
    valuelist[n-1] = workvalue;
    workvalue = strtok(NULL, ",");
  }
  valuelist = realloc(valuelist, sizeof (char*) * (n+1));
  // Get variables to swap
  char *variables;
  char tmpvariables[256];
  strcpy(tmpfunbuildstr, funexpresion);
  variables = strtok(tmpfunction, ":");
  // Swap variables and write
  funout = fopen("tmp/funeval.in", "w");
  for(int i = 0; i < strlen(function); i++){
    char *e;
    int index;
    e = strchr(variables, function[i]);
    index = (int)(e - variables);
    if (index < strlen(variables)){
      fprintf(funout, "%s", (index == 0) ? valuelist[index] : valuelist[index-1]);
    }
    else{
      fprintf(funout, "%c", function[i]);
    }
  }
  free(valuelist);
  fclose(funout);
  // Run function
  system("./calc tmp/funeval.in tmp/funeval.out");
  char *val = readfile("tmp/funeval.out");
  ofloat = atof(readfile("tmp/funeval.out"));
  return ofloat;
}
