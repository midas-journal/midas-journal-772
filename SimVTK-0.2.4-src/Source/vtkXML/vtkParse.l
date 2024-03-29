%option yylineno
%{

/*

This file must be translated to C and modified to build everywhere.

Run flex like this:

  flex --nounput -olex.yy.c vtkParse.l

Modify lex.yy.c:
  - remove TABs
  - change yy_n_chars declarations from "int yy_n_chars;" to
    "size_t yy_n_chars;" in both the yy_buffer_state structure
    and the global scope.
  - change num_to_read declaration from "int num_to_read;" to
    "size_t num_to_read;" in yy_get_next_buffer function.

*/

/* We do not care of interactive mode */
#define YY_NEVER_INTERACTIVE 1
#define YY_NO_UNPUT 1

/* Do not include unistd.h in generated source. */
#define YY_NO_UNISTD_H

/* Skip declaring this function.  It is a macro.  */
#define YY_SKIP_YYWRAP

#ifdef _WIN32
#pragma warning ( disable : 4018 )
#pragma warning ( disable : 4127 )
#pragma warning ( disable : 4131 )
#pragma warning ( disable : 4244 )
#pragma warning ( disable : 4251 )
#pragma warning ( disable : 4267 )
#pragma warning ( disable : 4305 )
#pragma warning ( disable : 4309 )
#pragma warning ( disable : 4706 )
#pragma warning ( disable : 4786 )
#endif

%}


%%

"/*" { int c1 = 0, c2 = input();
       for (;;)
         {
         if (c2 == 0)
           {
           fprintf(yyout,"Cannot find closing comment.\n");
           break;
           }
         if (c1 == '*' && c2 == '/') break;
         c1 = c2; c2 = input();
         }
     };

^[\t ]*"//BTX".*$ {
       int c1 = 0, c2 = 0, c3 = 0, c4 = 0, c5 = input();
       for (;;)
         {
         if (c5 == 0)
           {
           fprintf(yyout,"Cannot find matching //ETX.\n");
           break;
           }
         if (c1 == '/' && c2 == '/' && c3 == 'E' && c4 == 'T' && c5 == 'X') break;
         c1 = c2; c2 = c3; c3 = c4; c4 = c5; c5 = input();
         }
       for (;;)
         {
         if (c5 == 0) break;
         if (c5 == '\n') break;
         c5 = input();
         }
     };

^[\t ]*"#ifdef"[\t ]*"VTK_WORKAROUND_WINDOWS_MANGLE".*$ {
       int c1 = 0, c2 = 0, c3 = 0, c4 = 0, c5 = 0, c6 = input();
       for (;;)
         {
         if (c6 == 0)
           {
           fprintf(yyout,"Cannot find matching #endif.\n");
           break;
           }
         if (c1 == '#' && c2 == 'e' && c3 == 'n' && c4 == 'd' && c5 == 'i' && c6 == 'f') break;
         c1 = c2; c2 = c3; c3 = c4; c4 = c5; c5 = c6; c6 = input();
         }
       for (;;)
         {
         if (c6 == 0) break;
         if (c6 == '\n') break;
         c6 = input();
         }
     };

^[\t ]*"// .NAME".* {
     int pos = 1;
     while (yytext[pos-1] != 'M' || yytext[pos] != 'E')
       {
       pos++;
       }
     yylval.str = (char *)malloc(yyleng + 1 - pos - 1);
     memcpy(yylval.str,yytext+ pos + 1,yyleng - pos - 1);
     yylval.str[yyleng - pos - 1] = '\0';
     data.NameComment = vtkstrdup(yylval.str);
     };

^[\t ]*"// .SECTION Description".* {
     CommentState = 1;
     data.Description = (char*)malloc(100000);
     data.Description[0] = '\0';
     };

^[\t ]*"// .SECTION See Also".* {
     CommentState = 3;
     data.SeeAlso = (char*)malloc(100000);
     data.SeeAlso[0] = '\0';
     };

^[\t ]*"// .SECTION see also".* {
     CommentState = 3;
     data.SeeAlso = (char*)malloc(100000);
     data.SeeAlso[0] = '\0';
     };

^[\t ]*"// .SECTION Caveats".* {
     CommentState = 4;
     data.Caveats = (char*)malloc(100000);
     data.Caveats[0] = '\0';
     };

^[\t ]*"// Description:".* {
     CommentState = 2;
     HaveComment = 1;
     CommentText[0] = '\0';
     };

^[\t ]*[\r\n]  {
     HaveComment = 0;
     CommentState = 0;
     };

^[\t ]*"//".*   {
     int pos = 1;
     while (yytext[pos-1] != '/' || yytext[pos] != '/') pos++;
     yylval.str = (char *)malloc(yyleng + 1 - pos - 1 + 1);
     memcpy(yylval.str,yytext+ pos + 1,yyleng - pos - 1);
     yylval.str[yyleng - pos - 1] = '\n';
     yylval.str[yyleng - pos] = '\0';
     switch (CommentState)
       {
       case 1: strcat(data.Description,yylval.str); break;
       case 2: strcat(CommentText,yylval.str); break;
       case 3: strcat(data.SeeAlso,yylval.str); break;
       case 4: strcat(data.Caveats,yylval.str); break;
       }
     };

"//".* ;

[A-Za-z0-9_]*"_EXPORT" ;

"vtkNotUsed"[ ]*"("[^)]*")" {
     int i; int j = 0;
     while (yytext[j]!='(') { j++; }
     j++; i = j;
     while (yytext[j]!=')') { j++; }
     yylval.str = (char *)malloc(j-i+1);
     if (j > i) { strncpy(yylval.str, &yytext[i], j-i); }
     yylval.str[j-i] = '\0';
     return(ID);
     };

"["[\t\n\r\ ]*[1-9][0-9]*[\t\n\r ]*"]"  {
     sscanf(yytext+1,"%d",&yylval.integer);
     return(ARRAY_NUM);
     };

("friend"[\t\n\r ]+)?("template"[\t\n\r ]*"<"[^>]*">"[\t\n\r ]*)?"class"[\t\n\r ]+[a-zA-Z_][a-zA-Z0-9_]*("::"[a-zA-Z_][a-zA-Z0-9_]*)*[\t\n\r ]*";" {
     return(CLASS_REF);
     };

("friend"[\t\n\r ]+)?("template"[\t\n\r ]*"<"[^>]*">"[\t\n\r ]*)?"struct"[\t\n\r ]+[a-zA-Z_][a-zA-Z0-9_]*("::"[a-zA-Z_][a-zA-Z0-9_]*)*[\t\n\r ]*";" {
     return(CLASS_REF);
     };

"void"[\t\n\r ]*"("[\t\n\r ]*"*"[a-zA-Z0-9_]*[\t\n\r ]*")"[\t\n\r ]*"("[\t\n\r ]*"void"[\t\n\r ]*"*"[\n\t ]*")" {
     return(VAR_FUNCTION);
     };

"short"[\t\n\r ]*"int" return(SHORT);
"long"[\t\n\r ]*"int"  return(LONG);
"int"[\t\n\r ]*"short" return(SHORT);
"int"[\t\n\r ]*"long"  return(LONG);

"long"[\t\n\r ]*"long"  return(LONG_LONG);
"int"[\t\n\r ]*"long"[\t\n\r ]*"long"  return(LONG_LONG);
"long"[\t\n\r ]*"long"[\t\n\r ]*"int"  return(LONG_LONG);

"__int64"  return(INT64__);

"signed"[\t\n\r ]*"char"  return(SIGNED_CHAR);

"ostream"       return(OSTREAM);
"istream"       return(ISTREAM);

"class"         return(CLASS);
"struct"        return(CLASS);
"public"        return(PUBLIC);
"private"       return(PRIVATE);
"protected"     return(PROTECTED);
"int"           return(INT);
"float"         return(FLOAT);
"short"         return(SHORT);
"long"          return(LONG);
"double"        return(DOUBLE);
"void"          return(VOID);
"char"          return(CHAR);
"bool"          return(BOOL);
"enum"          return(ENUM);
"union"         return(UNION);
"virtual"       return(VIRTUAL);
"const"         return(CONST);
"mutable"       return(MUTABLE);
"operator"      return(OPERATOR);
"unsigned"      return(UNSIGNED);
"friend"        return(FRIEND);
"inline"        return(INLINE);
"static"        return(STATIC);
"template"      return(TEMPLATE);
"typename"      return(TYPENAME);
"typedef"       return(TYPEDEF);
"namespace"     return(NAMESPACE);
"using"         return(USING);
"new"           return(NEW);
"delete"        return(DELETE);

"vtkFloatingPointType" return(DOUBLE);
"vtkIdType"            return(IdType);
"vtkStdString"         return(StdString);
"vtkUnicodeString"     return(UnicodeString);
"vtkSetMacro"          return(SetMacro);
"vtkGetMacro"          return(GetMacro);
"vtkSetStringMacro"    return(SetStringMacro);
"vtkGetStringMacro"    return(GetStringMacro);
"vtkSetClampMacro"     return(SetClampMacro);
"vtkSetObjectMacro"    return(SetObjectMacro);
"vtkGetObjectMacro"    return(GetObjectMacro);
"vtkBooleanMacro"      return(BooleanMacro);
"vtkSetVector2Macro"   return(SetVector2Macro);
"vtkSetVector3Macro"   return(SetVector3Macro);
"vtkSetVector4Macro"   return(SetVector4Macro);
"vtkSetVector6Macro"   return(SetVector6Macro);
"vtkGetVector2Macro"   return(GetVector2Macro);
"vtkGetVector3Macro"   return(GetVector3Macro);
"vtkGetVector4Macro"   return(GetVector4Macro);
"vtkGetVector6Macro"   return(GetVector6Macro);
"vtkSetVectorMacro"    return(SetVectorMacro);
"vtkGetVectorMacro"    return(GetVectorMacro);
"vtkViewportCoordinateMacro" return(ViewportCoordinateMacro);
"vtkWorldCoordinateMacro" return(WorldCoordinateMacro);
"vtkExportedTypeMacro" return(TypeMacro);
"vtkExportedTypeRevisionMacro" return(TypeMacro);
"vtkTypeMacro"         return(TypeMacro);
"vtkTypeRevisionMacro" return(TypeMacro);
"VTK_LEGACY"           return(VTK_LEGACY);
"VTK_WRAP_EXTERN"      ;
"VTK_BYTE_SWAP_DECL"   return(VTK_BYTE_SWAP_DECL);
"vtkTypeInt8"          return(TypeInt8);
"vtkTypeUInt8"         return(TypeUInt8);
"vtkTypeInt16"         return(TypeInt16);
"vtkTypeUInt16"        return(TypeUInt16);
"vtkTypeInt32"         return(TypeInt32);
"vtkTypeUInt32"        return(TypeUInt32);
"vtkTypeInt64"         return(TypeInt64);
"vtkTypeUInt64"        return(TypeUInt64);
"vtkTypeFloat32"       return(TypeFloat32);
"vtkTypeFloat64"       return(TypeFloat64);

"*"[\r\n\t ]*"const"   return(CONST_PTR);
"const"[\r\n\t ]*"="   return(CONST_EQUAL);

[0-9]+"."[0-9]*([eE][+-]?[0-9]+)?[fFlL]?  {
                     yylval.str = (char *)malloc(yyleng + 1);
                     memcpy(yylval.str,yytext,yyleng);
                     yylval.str[yyleng] = '\0';
                     return(FLOAT_LITERAL);
                    }
"0x"[0-9a-fA-F]+[uU]?[lL]?      {
                     yylval.str = (char *)malloc(yyleng + 1);
                     memcpy(yylval.str,yytext,yyleng);
                     yylval.str[yyleng] = '\0';
                     return(HEX_LITERAL);
                    }
[0-9]+[uU]?[lL]?      { yylval.str = (char *)malloc(yyleng + 1);
                     memcpy(yylval.str,yytext,yyleng);
                     yylval.str[yyleng] = '\0';
                     return(INT_LITERAL);
                    }

\"([^\"]|\\\")*\"      {
                yylval.str = (char *)malloc(yyleng + 1);
                memcpy(yylval.str,yytext,yyleng);
                yylval.str[yyleng] = '\0';
                return(STRING_LITERAL);
                }

\'([^\']|\\\')+\'      {
                yylval.str = (char *)malloc(yyleng + 1);
                memcpy(yylval.str,yytext,yyleng);
                yylval.str[yyleng] = '\0';
                return(CHAR_LITERAL);
                }

^"#"[\t ]*"define"[\t ]+"VTK_"[a-zA-Z0-9_]+.*$ {
                int i;
                for (i = 0; i < yyleng && yytext[i] != 'V'; i++) { ; };
                yylval.str = (char *)malloc(yyleng - i + 1);
                memcpy(yylval.str, &yytext[i], yyleng-i);
                yylval.str[yyleng-i] = '\0';
                return (VTK_CONSTANT_DEF); }

^"#"(\\\n|\\\r\n|[^\n])*$     ;


"vtk"[0-9a-zA-Z_]*  { yylval.str = (char *)malloc(yyleng + 1);
                     memcpy(yylval.str,yytext,yyleng);
                     yylval.str[yyleng] = '\0';
                     return(VTK_ID);
                    }

[a-zA-Z_][0-9a-zA-Z_]*  { yylval.str = (char *)malloc(yyleng + 1);
                          memcpy(yylval.str,yytext,yyleng);
                          yylval.str[yyleng] = '\0';
                          return(ID);
                        }

"("[\t\n\r ]*"&"  return(LPAREN_AMPERSAND);
"("[\t\n\r ]*([a-zA-Z_][a-zA-Z0-9_]*::)*"*" {
                int i = 1;
                int j;
                while (yytext[i]==' ' || yytext[i]=='\t' ||
                       yytext[i]=='\r' || yytext[i]=='\n') { i++; }
                j = i;
                while (yytext[j]!='*') { j++; }
                yylval.str = (char *)malloc(j-i+1);
                if (j > i) { strncpy(yylval.str, &yytext[i], j-i); }
                yylval.str[j-i] = '\0';
                return(LPAREN_POINTER);
                }

[\t\n\r ] ;

"<<="             return(OP_LSHIFT_EQ);
">>="             return(OP_RSHIFT_EQ);
"<<"              return(OP_LSHIFT);
"->*"             return(OP_ARROW_POINTER);
"->"              return(OP_ARROW);
">>"              return(OP_RSHIFT);
"++"              return(OP_INCR);
"--"              return(OP_DECR);
"+="              return(OP_PLUS_EQ);
"-="              return(OP_MINUS_EQ);
"*="              return(OP_TIMES_EQ);
"/="              return(OP_DIVIDE_EQ);
"%="              return(OP_REMAINDER_EQ);
"&="              return(OP_AND_EQ);
"|="              return(OP_OR_EQ);
"^="              return(OP_XOR_EQ);
"&&="             return(OP_LOGIC_AND_EQ);
"||="             return(OP_LOGIC_OR_EQ);
"&&"              return(OP_LOGIC_AND);
"||"              return(OP_LOGIC_OR);
"=="              return(OP_LOGIC_EQ);
"!="              return(OP_LOGIC_NEQ);
"<="              return(OP_LOGIC_LEQ);
">="              return(OP_LOGIC_GEQ);
"..."             return(ELLIPSIS);
"::"              return(DOUBLE_COLON);

"[" { return(yytext[0]); }
"]" { return(yytext[0]); }

[~{}()<>:;*/%=,&.!+|^\-] { return(yytext[0]); }

.                return(OTHER);
%%

