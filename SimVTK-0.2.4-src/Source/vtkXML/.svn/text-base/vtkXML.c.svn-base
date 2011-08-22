/*=========================================================================

  Program:   Visualization Toolkit
  Module:    $RCSfile: vtkXML.c,v $

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/

/* Modified code from vtkWrapPython.c to make new parser vtkXML.c */

/*
 The vtkXML program will read VTK header files and produce an XML
 representation of the interface to the VTK classes.  The main entry
 point in this file is  vtkParseOutput(FILE *fp, FileInfo *data)
 where "FILE *fp" is the output file handle and "FileInfo *data" is
 the data structure that vtkParse.tab.c creates from the header.
 
 The files "vtkXML.c" and "xmlhints" are the only files in this directory
 that should be modified.  The vtkParse.xxx files are bison/flex generated
 parser files that are part of the VTK wrapper generators.  The vtkParse
 files parse the header files, while vtkXML.c is the back-end that writes
 out the XML files.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "vtkParse.h"
#include "vtkConfigure.h"

/* These are some useful macros based on vtkParseType.h */

#define typeBaseType(x)     ((x) & VTK_PARSE_BASE_TYPE & ~VTK_PARSE_UNSIGNED)
#define typeIsFloat(x)      (typeBaseType(x) == VTK_PARSE_FLOAT)
#define typeIsVoid(x)       (typeBaseType(x) == VTK_PARSE_VOID)
#define typeIsChar(x)       (typeBaseType(x) == VTK_PARSE_CHAR)
#define typeIsInt(x)        (typeBaseType(x) == VTK_PARSE_INT)
#define typeIsShort(x)      (typeBaseType(x) == VTK_PARSE_SHORT)
#define typeIsLong(x)       (typeBaseType(x) == VTK_PARSE_LONG)
#define typeIsDouble(x)     (typeBaseType(x) == VTK_PARSE_DOUBLE)
#define typeIsVtkObject(x)  (typeBaseType(x) == VTK_PARSE_VTK_OBJECT)
#define typeIsIdType(x)     (typeBaseType(x) == VTK_PARSE_ID_TYPE)
#define typeIsLongLong(x)   (typeBaseType(x) == VTK_PARSE_LONG_LONG)
#define typeIs__Int64(x)    (typeBaseType(x) == VTK_PARSE___INT64)
#define typeIsSignedChar(x) (typeBaseType(x) == VTK_PARSE_SIGNED_CHAR)
#define typeIsBool(x)       (typeBaseType(x) == VTK_PARSE_BOOL)

#define typeIsPrimitive(x)  (typeBaseType(x) == VTK_PARSE_FLOAT || \
                             typeBaseType(x) == VTK_PARSE_CHAR || \
                             typeBaseType(x) == VTK_PARSE_INT || \
                             typeBaseType(x) == VTK_PARSE_SHORT || \
                             typeBaseType(x) == VTK_PARSE_LONG || \
                             typeBaseType(x) == VTK_PARSE_DOUBLE || \
                             typeBaseType(x) == VTK_PARSE_SIGNED_CHAR || \
                             typeBaseType(x) == VTK_PARSE_BOOL)

#define typeIsUnsigned(x)   (((x) & VTK_PARSE_UNSIGNED) != 0)

#define typeIndirection(x)  ((x) & VTK_PARSE_INDIRECT)
#define typeIsIndirect(x)   (typeIndirection(x) != 0)
#define typeIsPointer(x)    (typeIndirection(x) == VTK_PARSE_POINTER)

#define typeQualifier(x)    ((x) & VTK_PARSE_QUALIFIER)
#define typeHasQualifier(x) (typeQualifier(x) != 0)
#define typeIsStatic(x)     (typeQualifier(x) == VTK_PARSE_STATIC)
#define typeIsConst(x)      (typeQualifier(x) == VTK_PARSE_CONST)

#define typeIsFunction(x)   ((x) == VTK_PARSE_FUNCTION)


/* vtkXML will print this if any unsupported types or
   methods are encountered */
#define VTKXML_UNSUPPORTED "UNSUPPORTED"


/* used to store max size of array of expected number of
   get/set/add/remove functions */
#define MAX_ARRAY_SIZE 100

/* return the base type as a string */
const char *baseTypeName(int type)
{
  switch(typeBaseType(type))
    {
    case VTK_PARSE_FLOAT: return "float";
    case VTK_PARSE_VOID:  return "void";
    case VTK_PARSE_CHAR:  return "char";
    case VTK_PARSE_INT:   return "int";
    case VTK_PARSE_SHORT: return "short";
    case VTK_PARSE_LONG:  return "long";
    case VTK_PARSE_DOUBLE: return "double";
    case VTK_PARSE_UNKNOWN: return "";
    case VTK_PARSE_VTK_OBJECT: return "vtkObject";
    case VTK_PARSE_ID_TYPE: return "vtkIdType";
    case VTK_PARSE_LONG_LONG: return "long long";
    case VTK_PARSE___INT64: return "__int64";
    case VTK_PARSE_SIGNED_CHAR: return "signed char";
    case VTK_PARSE_BOOL:  return "bool";
    }

  return "";
}

/* next few functions are there to have final list in order */

/* lexical comparison of name of function "i" with name of function "j" */
static int compareNames(FileInfo *data, int i, int j)
{
  return strcmp(data->Functions[i].Name,data->Functions[j].Name);
}

/* swap integer item "i" with item "j" */
static void swapArrayItems(int arr[], int i, int j)
{
  int temp = arr[i];
  arr[i] = arr[j];
  arr[j] = temp;
}

/* sort functions lexically between indices "start" and "ends" */
static void sortByName(FileInfo *data, int functionList[], int start, int ends)
{
  int i, location = start;
  if (ends <= start)
    {
    return;
    }
  for (i = start; i < ends; i++)
    {
    if (compareNames(data, functionList[ends], functionList[i]) > 0)
      {
      swapArrayItems(functionList, location, i);
      location++;
      }
    }
  swapArrayItems(functionList, location, ends);
  sortByName(data, functionList, start, location - 1);
  sortByName(data, functionList, location + 1, ends);
}

/* indent to the specified indentation level */
static void indent(FILE *fp, int indentation)
{
  while (indentation > 0)
    {
    fprintf(fp, "\t");
    indentation--;
    }
}

/* convert special characters in a string into their escape codes,
 * so that the string can be quoted in an xml file (the specified
 * maxlen must be at least 32 chars)*/
static const char *quoteForXML(const char *comment, int maxlen)
{
  static char *result = 0;
  static int oldmaxlen = 0;
  int i, j, n;

  if (maxlen > oldmaxlen)
    {
    if (result)
      {
      free(result);
      }
    result = (char *)malloc((size_t)(maxlen+1));
    oldmaxlen = maxlen;
    }

  if (comment == NULL)
    {
    return "";
    }

  j = 0;

  n = (int)strlen(comment);
  for (i = 0; i < n; i++)
    {
    if (comment[i] == '<')
      {
      strcpy(&result[j],"&lt;");
      j += 4;
      }
    else if (comment[i] == '>')
      {
      strcpy(&result[j],"&gt;");
      j += 4;
      }      
    else if (comment[i] == '&')
      {
      strcpy(&result[j],"&amp;");
      j += 5;
      }      
    else if (comment[i] == '\"')
      {
      strcpy(&result[j],"&quot;");
      j += 6;
      }
    else if (comment[i] == '\'')
      {
      strcpy(&result[j],"&apos;");
      j += 6;
      }
    else if (isprint(comment[i]))
      {
      result[j] = comment[i];
      j++;
      }
    else if (isspace(comment[i]))
      { /* also copy non-printing characters */
      result[j] = comment[i];
      j++;
      }
    if (j >= maxlen - 21)
      {      
      sprintf(&result[j]," ...\\n [Truncated]\\n");
      j += (int)strlen(" ...\\n [Truncated]\\n");
      break;
      }
    }
  result[j] = '\0';

  return result;
}

/* count the number of arguments that a function in VTK will take */
static int countTotalArguments(FunctionInfo *func)
{
  int count = 0, i;
  for (i = 0; i < func->NumberOfArguments; i++)
    {
    /* make sure not an array or pointer or any such thing */
    if (!typeIsIndirect(func->ArgTypes[i]))
      {
      count++;  /* get here if is not an array */
      }
    /* is an array and doesn't have number of arguments that array takes */
    else if (typeIsPointer(func->ArgTypes[i]) && !func->ArgCounts[i])
      {
      count = -1;
      break;
      }
    /* if is an array then just take the argCount provided in functionInfo */
    else if (typeIsPointer(func->ArgTypes[i]))
      {
      /* if is an array add the value in the count */
      count += func->ArgCounts[i];
      }
    }
  return count;
}

/* return 1 if all arguments are the same type, 0 if types are mixed,
 * e.g. myfunc(double red, double green, double blue)  ->  return 1
 * but myfunc(int i, int a[3])  ->  return 0  */
static int hasUnmixedArguments(FunctionInfo *func)
{
  int i, type;
  for (i = 0, type = func->ArgTypes[0]; i < func->NumberOfArguments; i++)
    {
    if (type != func->ArgTypes[i]) 
      {
      return 0;
      }
    }
  return 1;
}

/* check for particular paired set/get functions where func1 is a Get
 * function that takes an integer index and returns a primitive, and func2
 * is a Set function that takes in integer index as its first argument
 * and the same primitive as its second argument: for example,
 * func1 = "double GetValue(int)", func2 = "void SetValue(int, double)" */
static int indexedArgumentCheck(FunctionInfo *func1, FunctionInfo *func2)
{
  /* make sure the second function (set) has 2 arguments and the
   * first (get) has 1 */
  if (func2->NumberOfArguments == 2 && func1->NumberOfArguments == 1)
    {
    /* make sure first argument is an integer and the second argument
     * matches the first functions return type */
    /* want second argument to be a primitive number type other than int */
    if (typeIsInt(func2->ArgTypes[0]) &&
        (typeBaseType(func2->ArgTypes[1]) == typeBaseType(func1->ReturnType))
        && (typeIsFloat(func2->ArgTypes[1]) ||
            typeIsShort(func2->ArgTypes[1]) || 
            typeIsLong(func2->ArgTypes[1])  || 
            typeIsDouble(func2->ArgTypes[1]) ) )
      {
      return 1;
      }
    }
  return 0;
}

/* check to see if a method is of the form "SetValue(int, double)" where
 * the second argument can actually be any numerical primitive.  */
int singlePossibleIndexedArgumentCheck(FunctionInfo *func)
{
  /* make sure first argument is an integer, 
   * want second argument to be a primitive number type other than int */
  if (func->NumberOfArguments == 2 &&
      typeIsInt(func->ArgTypes[0]) &&
      (typeIsFloat(func->ArgTypes[1]) ||
       typeIsShort(func->ArgTypes[1]) || 
       typeIsLong(func->ArgTypes[1])  || 
       typeIsBool(func->ArgTypes[1])  || 
       typeIsDouble(func->ArgTypes[1]) ) )
    {
    return 1;
    }
  return 0;
}

/* check to see if a method is of the form "double GetValue(int index)" */
int singlePossibleIndexedReturnCheck(FunctionInfo *func)
{
  if (func->NumberOfArguments == 1 &&
      typeIsInt(func->ArgTypes[0]) && 
      (typeIsPrimitive(func->ReturnType) ) )
    {
    return 1;
    }
  return 0;
}

/* check whether the function has more than one array argument. */
int hasMultipleArrayArguments(FunctionInfo *func)
{
  if (func->NumberOfArguments > 1 &&
      typeIsPointer(func->ArgTypes[0]) &&
      typeIsPointer(func->ArgTypes[1]) )
    {
    return 1;
    }
  return 0;
}
  
/* check whether the function has only scalars as aguments */
int hasOnlyScalarArguments(FunctionInfo *func)
{
  int i;
  for (i = 0; i < func->NumberOfArguments; i++) 
    {
    if (typeIsIndirect(func->ArgTypes[i]) &&
        !typeIsPointer(func->ArgTypes[i]) )
      {
      return 0;
      }
    }
  return 1;
}
  
/* goes through all the functions in the data list and puts them into
 * the proper array based on the function name so can later be compared
 * to extract only the wanted parameter and input types.*/
void separateFunctions(FILE *fp, FileInfo *data, int addFunctions[],
                       int *endOfAddFunctions, int removeFunctions[],
                       int *endOfRemoveFunctions, int setFunctions[],
                       int *endOfSetFunctions, int getFunctions[],
                       int *endOfGetFunctions, int protectedFunctions[],
                       int *endOfProtectedFunctions)
{
  int i;
  for (i = 0; i < data->NumberOfFunctions; i++)
    {
    if ((!data->Functions[i].IsOperator &&   /* no operators */
         !data->Functions[i].ArrayFailure && /* no bad arrays */
         data->Functions[i].IsPublic &&    /* only public methods */
         data->Functions[i].Name) &&  /* only methods with parseable names */
        /* only non-static methods */
        !typeIsStatic(data->Functions[i].ReturnType) &&
        /* make sure not an exception */
        data->Functions[i].HintSize != -1  && 
        /* only want to deal with normal array/pointers or scalar values */
        (typeIsPointer(data->Functions[i].ReturnType) ||
         !typeIsIndirect(data->Functions[i].ReturnType) ))
      {
      /* Getting all functions that start with Add */
      if (strncmp(data->Functions[i].Name, "Add", 3) == 0)  
        {
        (*endOfAddFunctions)++;
        addFunctions[*endOfAddFunctions] = i;
        }
      /* Getting all functions that start with Remove */
      else if (strncmp(data->Functions[i].Name, "Remove", 6) == 0)
        {
        (*endOfRemoveFunctions)++;
        removeFunctions[*endOfRemoveFunctions] = i;
        }
      /* Getting all functions that start with Set */
      else if (strncmp(data->Functions[i].Name, "Set", 3) == 0)
        {
        if (data->Functions[i].NumberOfArguments > 0)
          {
          /* don't allow SetColor to use "unsigned char" */
          if (strcmp(data->Functions[i].Name + 3, "Color") != 0 ||
              !typeIsChar(data->Functions[i].ArgTypes[0]))
            {
            (*endOfSetFunctions)++;
            setFunctions[*endOfSetFunctions] = i;
            }
	  }
        }
      /* Getting all functions that start with Get */
      else if (strncmp(data->Functions[i].Name, "Get", 3) == 0)
        {
        /* vtkImageReader2::GetHeaderSize() is overridden in a bad way */
        if (strcmp(data->Functions[i].Name + 3, "HeaderSize") != 0)
          {
          (*endOfGetFunctions)++;
          getFunctions[*endOfGetFunctions] = i;
          }
        }
      }
    /* really only care about those functions that may be added otherwise
     * so only take it if it may be passed into the XML*/
    if (data->Functions[i].IsProtected &&    /* want protected methods */
        data->Functions[i].Name && /* only if has a parseable name */
        ((strncmp(data->Functions[i].Name, "Add", 3) == 0) ||
         (strncmp(data->Functions[i].Name, "Set", 3) == 0) ||
         (strncmp(data->Functions[i].Name, "Get", 3) == 0)) )
      {
      (*endOfProtectedFunctions)++;
      protectedFunctions[*endOfProtectedFunctions] = i;
      }
    } /* end of for loop */
}

/* remove the duplicate names from the lists of functions so that the
 * XML only has one copy of each possible function name for each type
 * of function*/
void removeDuplicateFunctions(FileInfo *data,
  int functions[], int *endOfFunctions)
{
  int i, j;
  int location = -1;
  int check = 0;

  for (i = 0; i <= *endOfFunctions; i++)
    {
    check = 0;
    for (j = 0; j <= location; j++)
      {
      if (strcmp(data->Functions[functions[i]].Name,
                 data->Functions[functions[j]].Name) == 0)
        {
        /* so already in the list */
        check = 1;
        break;
        }
      }
    if (check == 0)
      {
      location++;
      functions[location] = functions[i];
      }
    }
  *endOfFunctions = location;
}
  
/* remove other bad functions (ie. those with mixed argument types or
 * whatever else is decided to be not wanted) */
void removeBadFunctions(FileInfo *data, int functions[], int *endOfFunctions)
{
  int i;
  int location =-1;

  for (i = 0; i <= *endOfFunctions; i++)
    {
    /* okay if is an indexed function */
    if ((singlePossibleIndexedArgumentCheck(&data->Functions[functions[i]]) ||
         /* don't want functions with different types of arguments */ 
         hasUnmixedArguments(&data->Functions[functions[i]])) &&
        /* don't want functions with multiple array arguments */
        !hasMultipleArrayArguments(&data->Functions[functions[i]]) &&
        /* don't want functions with non-scalar or non-pointer arguments */
        hasOnlyScalarArguments(&data->Functions[functions[i]]))
      {
      location++;
      functions[location] = functions[i];
      }
    }
  *endOfFunctions = location;
}

/* put into second array only those functions that have the same ending Name
 * in both lists (ignoring amounts specified in word1Lengths and word2Lengths
 * part). 
 * Parameters are data = FileInfo created from parser
 * firstFunctions = list of indices to check in data->Functions
 * endOfFirstFunctions = pointer to int of the last currently used index
 *   in firstFunctions
 * word1Length = length at start of function Name 1 to ignore
 *
 * used here with 'get' as first and 'set' as second... or 'remove' first
 * and 'add' second*/
void checkMatchBetweenAddAndRemoveList(FILE *fp, FileInfo *data,
                                       int firstFunctions[],
                                       int *endOfFirstFunctions,
                                       int word1Length, int secondFunctions[],
                                       int *endOfSecondFunctions,
                                       int word2Length)
{
  int i, j, k, alreadyIn;
  int special = 0;
  /* lastUsedIndex is to know where the next usable function should be
     placed. */
  int lastUsedIndex = -1;

  /* loop through all of second functions */
  for (i = 0; i <= *endOfSecondFunctions; i++)
    {
    alreadyIn = -1;
    for (j = 0; j <= *endOfFirstFunctions; j++)
      {
      special = 0;
      /* want to make sure that the ends of the function names are the same,
       * and that if it is a get function it takes no arguments (to 
       * bypass RGBA/Z buffer, complex functions that are to be ignored.
       * Word1Length != word2Length is because both add and  remove
       * take 1 argument always so no way have one as zero, so easy check
       * to make sure not comparing add/remove is just checking the lengths.
       * NOT VERY ROBUST THOUGH! */
      if (word1Length == word2Length) /* if using set/get */
        {
        special = indexedArgumentCheck(&data->Functions[firstFunctions[j]],
                                       &data->Functions[secondFunctions[i]]);
        }
      /* either get takes no arguments, is add/remove, or is an indexed
       * function */
      if (strcmp(data->Functions[secondFunctions[i]].Name + word2Length,
                 data->Functions[firstFunctions[j]].Name + word1Length) == 0 &&
          ((data->Functions[firstFunctions[j]].NumberOfArguments == 0) ||
           word1Length != word2Length || special == 1))
        {
        /* make sure it is not in the list already */
        for (k = 0; k <=lastUsedIndex; k++)
          {
          if (strcmp(data->Functions[secondFunctions[k]].Name,
                     data->Functions[secondFunctions[i]].Name) == 0)
            {
            alreadyIn = i;
            break;
            }
          }
        if (alreadyIn == -1)
          {
          lastUsedIndex++;
          secondFunctions[lastUsedIndex] = secondFunctions[i];
          break;
          }
        }
      }
    }
  /* array likely shrunk due to removing unnecessary stuff so change
   * endOfGetFunctions to new proper value */
  *endOfSecondFunctions = lastUsedIndex;        
}

/* Take a list of Set functions and a list of Get methods and look for 
 * matches, i.e. Get and Set methods for the same parameter.  The results
 * are put into lists of all Get-only methods, Set-only methods, and 
 * matched Set/Get methods.  The index of the last item in each array
 * is also returned. */
static void categorizeSetGetFunctions(
  FILE *fp, FileInfo *data,
  int getFunctions[], int *endOfGetFunctions,
  int setFunctions[], int *endOfSetFunctions,
  int setOnlyFunctions[], int *endOfSetOnlyFunctions,
  int getOnlyFunctions[], int *endOfGetOnlyFunctions,
  int getAndSetFunctions[], int *endOfGetAndSetFunctions)
{
  int i, j, found;
  
  for (i = 0; i <= *endOfGetFunctions; i++)
    {
    for (j = 0; j<= *endOfSetFunctions; j++)
      {
          /* have the same name */
      if ((strcmp(data->Functions[getFunctions[i]].Name + 3,
                  data->Functions[setFunctions[j]].Name + 3) == 0) &&
          /* neither is indexed */
     !singlePossibleIndexedReturnCheck(&data->Functions[getFunctions[i]]) &&
     !singlePossibleIndexedArgumentCheck(&data->Functions[setFunctions[j]]) &&
          /* arguments match the return type (ignoring const, signedness) */
          (typeBaseType(data->Functions[getFunctions[i]].ReturnType) ==
           typeBaseType(data->Functions[setFunctions[j]].ArgTypes[0])) &&
          (typeIndirection(data->Functions[getFunctions[i]].ReturnType) ==
           typeIndirection(data->Functions[setFunctions[j]].ArgTypes[0])) &&
          /* returns an array and has a hint size */
          ((typeIsPointer(data->Functions[getFunctions[i]].ReturnType) &&
            data->Functions[getFunctions[i]].HaveHint &&
            /* and has the same arg count as hint size */
            countTotalArguments(&data->Functions[setFunctions[j]]) ==
            data->Functions[getFunctions[i]].HintSize) ||
           /* returns a single value and set only takes a single argument */
           (!typeIsIndirect(data->Functions[getFunctions[i]].ReturnType) &&
            countTotalArguments(&data->Functions[setFunctions[j]]) == 1) ||
           /* for char* as will have unkown argument size and return size */
           (typeIsPointer(data->Functions[getFunctions[i]].ReturnType) &&
            !data->Functions[getFunctions[i]].HaveHint &&
            countTotalArguments(&data->Functions[setFunctions[j]]) == -1)))
        {
        /* So know function has a method in both get and set with the same
         * number of arguments/return array size */
        (*endOfGetAndSetFunctions)++;
        getAndSetFunctions[(*endOfGetAndSetFunctions)] = setFunctions[j];
        break;
        }
      }
    }
  /* Now have all functions that are used in both gets and sets so need to
   * find those that are only in gets now */
  
  for (i = 0; i <= *endOfGetFunctions; i++)
    {
    found = 0;
         /* don't want to include GetClassName */
    if ((strcmp(data->Functions[getFunctions[i]].Name, "GetClassName") == 0) ||
        /* don't want to include GetMTime */
        (strcmp(data->Functions[getFunctions[i]].Name, "GetMTime") == 0) ||
        /* don't want to include gets that take any arguments */
        (data->Functions[getFunctions[i]].NumberOfArguments > 0))
      {
      found  = 1;
      }
    for (j = 0; j <= *endOfGetAndSetFunctions; j++)
      {
      /* if it has the same name as one in both */
      if ((strcmp(data->Functions[getAndSetFunctions[j]].Name + 3,
                  data->Functions[getFunctions[i]].Name + 3) == 0))
        {
        found = 1;
        break;
        }
      }
    if (found == 0) /* so wasn't matched with a set function before */
      {
      (*endOfGetOnlyFunctions)++;
      getOnlyFunctions[(*endOfGetOnlyFunctions)] = getFunctions[i];
      }
    }
  /* Now have all functions that are used in only get or in both gets and
   * sets so need to find those that are only in sets now */
  for (i = 0; i <= *endOfSetFunctions; i++)
    {
    found = 0;
    for (j = 0; j <= *endOfGetAndSetFunctions; j++)
      {
      /* if it has the same name as one in both */
      if (strcmp(data->Functions[getAndSetFunctions[j]].Name + 3,
                 data->Functions[setFunctions[i]].Name + 3) == 0)
        {
        found = 1;
        break;
        }
      }
    if (found == 0)
      {
      /* so wasn't matched with a get function before */
      (*endOfSetOnlyFunctions)++;
      setOnlyFunctions[(*endOfSetOnlyFunctions)] = setFunctions[i];
      }
    }
}

/* checks for all Get functions that returned an object type and had no
 * matching set function.  These were all promoted to be Outputs.
 * Leaves only the promoted function indices in the getFunctions list.*/
void getPromotedOutputs(FILE *fp, FileInfo *data, int getFunctions[],
                        int *endOfGetFunctions, int setFunctions[],
                        int *endOfSetFunctions)
{
  int i, j, k, found, alreadyIn;
  int lastUsedIndex = -1;

  for (i = 0; i <= *endOfGetFunctions; i++)
    {
    found = 0; /* to check if there was a corresponding set function*/
    alreadyIn = -1; /* so only put each get function in once */

        /* returns an object*/
    if (typeIsVtkObject(data->Functions[getFunctions[i]].ReturnType) &&
        /* returns a pointer to the object
         *  (ie. no double pointers or direct objects) */
        typeIsPointer(data->Functions[getFunctions[i]].ReturnType) &&
        /* not actually an input of some sort */
        (strstr(data->Functions[getFunctions[i]].Name, "Input") == NULL) &&
        /* takes no arguments */
        (data->Functions[getFunctions[i]].NumberOfArguments == 0) )
      {
      /* goes through list of sorted set functions that have been matched
       * to a get function already.  If get name not found by time it
       * reaches position it should be alphabetically in set list, then the
       * get Function is promoted to an output. */
      for (j = 0;
           j <= *endOfSetFunctions &&
             strcmp(data->Functions[getFunctions[i]].Name + 3,
                    data->Functions[setFunctions[j]].Name + 3) >= 0;
           j++)
        {
        if (strcmp(data->Functions[getFunctions[i]].Name + 3,
                   data->Functions[setFunctions[j]].Name + 3) == 0 &&
            strcmp(data->Functions[getFunctions[i]].Name, "GetOutput") != 0)
          {
          found = 1;
          break;
          }
        }

      for (k = 0; k <= lastUsedIndex; k++)
        {
        if (strcmp(data->Functions[getFunctions[k]].Name,
                   data->Functions[getFunctions[i]].Name) == 0)
          {
          alreadyIn = i;
          break;
          }
        }

      if(found == 0 && alreadyIn == -1)
        {
        lastUsedIndex++;
        getFunctions[lastUsedIndex] = getFunctions[i];
        }
      }
    }
  /* array likely shrunk due to removal of those that were not promoted */
  *endOfGetFunctions = lastUsedIndex;
}

/* Write out the documentation for the class */
void ClassDocumentation(FILE *fp, FileInfo *data, int indentation)
{
  const char *text;
  size_t i, n;
  char temp[500];

  indent(fp, indentation);
  fprintf(fp, "<Documentation>\n");
  indentation++;

  indent(fp, indentation);
  fprintf(fp, "<Summary>");
  if (data->NameComment) 
    {
    text = data->NameComment;
    while (*text == ' ')
      {
      text++;
      }
    fprintf(fp,"\"%s\"",quoteForXML(text,500));
    }
  else
    {
    fprintf(fp,"\"%s - no description provided.\"",
            quoteForXML(data->ClassName,500));
    }
  fprintf(fp, "</Summary>\n");

  indent(fp, indentation);
  fprintf(fp, "<Description>\n");
  fprintf(fp, "\"");
  if (data->Description)
    {
    /* fprintf can only handle max 511 chars on some platforms,
     * use 400 since quoting can increase size. */
    n = (strlen(data->Description) + 200-1)/200;
    for (i = 0; i < n; i++)
      {
      strncpy(temp, &data->Description[200*i], 200);
      temp[200] = '\0';
      fprintf(fp,"%s",quoteForXML(temp,500));
      }
    }
  else
    {
    fprintf(fp, "No documentation provided.\n");
    }

  if (data->Caveats && data->Caveats[0] != '\0')
    {
    fprintf(fp, "\n .SECTION Caveats\n");
    /* fprintf can only handle max 511 chars on some platforms,
     * use 200 since quoting can increase size. */
    n = (strlen(data->Caveats) + 200-1)/200;
    for (i = 0; i < n; i++)
      {
      strncpy(temp, &data->Caveats[200*i], 200);
      temp[200] = '\0';
      fprintf(fp,"%s",quoteForXML(temp,500));
      }
    }

  if (data->SeeAlso && data->SeeAlso[0] != '\0')
    {
    fprintf(fp, "\n .SECTION See also\n ");

    text = data->SeeAlso;
    while(isspace(*text))
      {
      text++;
      }
    while(*text)
      { /* separate items by whitespace */
      n = 0;
      while(text[n] && !isspace(text[n]))
        {
        n++;
        }
      if (n > 0 && n < 400)
        {
        strncpy(temp, text, n);
        temp[n] = '\0';
        fprintf(fp,"%s",quoteForXML(temp,500));
        }
      text += n;
      while(isspace(*text))
        {
        text++;
        }
      if (n > 0 && *text)
        { /* if not last item, print a delimiter */
        fprintf(fp," ");
        }
      }
    }
  fprintf(fp, "\"\n");
  indent(fp, indentation);
  fprintf(fp, "</Description>\n");

  indentation--;
  indent(fp, indentation);
  fprintf(fp, "</Documentation>\n");
}

/* check to make sure that only print right stuff as input. Returns 1 when
 * was a set function that had been promoted to input. Returns 0 otherwise. */
int InputFunctions(FILE *fp, FunctionInfo *func, int indentation)
{
  int type_number;
  int value = 0;
 
  if (func->NumberOfArguments > 0)
    {
    type_number = func->ArgTypes[0];
    }
  else 
    {
    /* don't think it ever will get here since 'set' always (?) has
     * arguments, and 'add' always (?) has arguments */
     type_number = func->ReturnType;
    }
    /* only print for ones that take arguments in the add functions and take
     * none for sets */
  if ((func->NumberOfArguments != 1 && strncmp(func->Name,"Set", 3) != 0))
    {
    return 0;
    }
  /* don't want any real input/output
  if (strcmp(func->Name, "SetOutput") == 0 ||
      strcmp(func->Name, "SetInput") == 0) 
      {
      return 1;
      }
  */

  /* checking type so can decide if it is input or parameter.
   * Need object type to put into input. */
  if (typeIsVtkObject(type_number))
    {
    /* make it so that if starts with add/set will put into input. */
      indent(fp, indentation);
      fprintf(fp, "<Input>\n");
      indentation++;
      indent(fp, indentation);
      fprintf(fp, "<Input_Name>");
      fprintf(fp, "%s", func->Name+3);  /* +3 so don't get Add/Set */
      fprintf(fp, "</Input_Name>\n");
      indent(fp, indentation);
      fprintf(fp, "<Input_Type>");
      fprintf(fp, "%s", func->ArgClasses[0]);
      fprintf(fp, "</Input_Type>\n");
      /* all functions that are of type "Add" can be used as inputs multiple
       * times or none at all, so flagged as Optional and Repeatable. */
      if (strncmp(func->Name, "Add", 3) == 0)
        {
        indent(fp, indentation);
        fprintf(fp, "<Input_Flags>Repeatable,Optional</Input_Flags>\n");
        }
      /* all functions that are of type "Set" can be used or ignored,
       * so flagged as Optional. */
      if (strncmp(func->Name, "Set",3) == 0)
        {
        indent(fp, indentation);
        fprintf(fp, "<Input_Flags>Optional</Input_Flags>\n");
        }
      indentation--;
      indent(fp, indentation);
      fprintf(fp, "</Input>\n");
      value = 1;
    }
  return value;
}

/* Print out a function as a parameter type in XML format */
int ParameterFunctions(FILE *fp, FunctionInfo *func, int indentation,
                       int designator)
{
  int type_number;
  int total_arguments = 0;
  int typeOne = 0;
  int typeTwo = 0;
 
  if (func->NumberOfArguments > 0)
    {
    type_number = func->ArgTypes[0];
    typeOne = func->ArgTypes[0];
    typeTwo = typeOne;
    /* if has exactly 2 arguments (checking for the special cases where
     * the function takes an index then a double as the actual value */
    if (func->NumberOfArguments == 2)
      {
      typeTwo = func->ArgTypes[1];
      }
    }
  else 
    {
    type_number = func->ReturnType;
    }

  /*checking if it is primitive type*/
  if (typeIsPrimitive(type_number) &&
      /* checking to make sure is either a scalar or normal array/pointer */
      (typeIsPointer(type_number) || !typeIsIndirect(type_number)))
    {
    /* for set Methods can check argument number by counting arguments */
    if (designator == 0 || designator == 2)
      {
      total_arguments = countTotalArguments(func);
      }
    else if (designator == 1) /* for get methods check */
      {
      /* has an array return without a hint so unknown size */
      if (func->HaveHint == 0 && typeIsPointer(type_number)) 
        {
        total_arguments = -1;
        }
      else if (func->HaveHint == 1) /* check if has a hint */
        {
        total_arguments = func->HintSize;
        }
      else   /* not an array so a simple type */
        {
        total_arguments = 1;
        }
      }

    if (typeIsChar(type_number) || total_arguments != -1)
      {
      /* it's a char has a known array size (ex. not int* with unknown size) */
      indent(fp, indentation);
      fprintf(fp, "<Parameter>\n");
      indentation++;
      indent(fp, indentation);
      fprintf(fp, "<Parameter_Name>%s</Parameter_Name>\n", func->Name+3);
      indent(fp, indentation);
      fprintf(fp, "<Parameter_Type>");
      if (typeIsUnsigned(type_number)) /* unsigned */
        {
        fprintf(fp, "unsigned ");
        }
      fprintf(fp, "%s", baseTypeName(type_number));

      if (typeOne != typeTwo)
        {
        fprintf(fp, ",");
        if (typeIsUnsigned(typeTwo)) /* unsigned */
          {
          fprintf(fp, "unsigned ");
          }
        fprintf(fp, "%s", baseTypeName(typeTwo));
        }

      fprintf(fp, "</Parameter_Type>\n");
      indent(fp, indentation);
      fprintf(fp, "<Parameter_Size>");
      /* if set function has multiple arguments, then the number of
       * acceptable parameters is same as number of arguments */
      if (typeOne == typeTwo) /* normal old way */
        {
        if (total_arguments > 0)
          {
          fprintf(fp, "%i", total_arguments);  
          }
        else
          {
          /* for cases like char * where array size isn't given */
          fprintf(fp, "N");
          }
        if(typeIsPointer(type_number)) /* is an array */
          {
          fprintf(fp, "*");
          }
        }
      else
        {
        /* case where has index then value */
        fprintf(fp, "1,%i", (total_arguments - 1));
        if (typeIsPointer(typeTwo))
          {
          fprintf(fp, "*");
          }
        }
      fprintf(fp, "</Parameter_Size>\n");
      if (designator == 0)
        {
        indent(fp, indentation);
        fprintf(fp, "<Parameter_Flag>Set</Parameter_Flag>\n");
        }
      else if (designator == 1)
        {
        indent(fp, indentation);
        fprintf(fp, "<Parameter_Flag>Get</Parameter_Flag>\n");
        }
      else if (designator == 2)
        {
        indent(fp, indentation);
        fprintf(fp, "<Parameter_Flag>Both</Parameter_Flag>\n");
        }
      indentation--;
      indent(fp, indentation);
      fprintf(fp, "</Parameter>\n");
      return 1;
      }
    }
  return 0;
}

/* print all output types.  Includes output that has been promoted from a
 * partnerless Get Functions, as well as including the name of the class as
 * a final output parameter. */
void PrintOutput(FILE *fp, char *name, char* type, int indentation)
{
  if (strcmp(name, "Output") == 0)
    {
    /* so no real output as that will be handled by the MATLAB code and
     * instantiated objects */
    return;
    }
  indent(fp, indentation);
  fprintf(fp, "<Output>\n");
  indentation++;
  indent(fp, indentation);
  fprintf(fp, "<Output_Name>%s</Output_Name>\n", name);
  indent(fp, indentation);
  fprintf(fp, "<Output_Type>%s</Output_Type>\n", type);
  indentation--;
  indent(fp, indentation);
  fprintf(fp, "</Output>\n");
}
  
/* print all output types.  Includes output that has been promoted from a
 * partnerless Get Functions, as well as including the name of the class
 * as a final output parameter. */
void PrintProtectedFunctions(FILE *fp, char *name, int indentation)
{
  indent(fp, indentation);
  fprintf(fp, "<Protected_Function>\n");
  indentation++;
  indent(fp, indentation);
  fprintf(fp, "<Function_Name>%s</Function_Name>\n", name);
  indentation--;
  indent(fp, indentation);
  fprintf(fp, "</Protected_Function>\n");
}

/* main functions that takes a parsed FileInfo from vtk and produces a
 * specific vtkXML format for desired functions to be incorporated in SimVTK
 * (ie. certain add, remove, get and set methods). */
void vtkParseOutput(FILE *fp, FileInfo *data)
{
  /* store the last element index of the add, set, remove, get arrays so
   * easier when checking for stopping to compare values.  setForInputOnly
   * is used to check if any set methods were used for parameters and not
   * just promoted inputs.  indentation is to make sure that the XML format
   * is proper. */
  int i;
  int endOfAddFunctions = -1;
  int endOfSetFunctions = -1;
  int endOfRemoveFunctions = -1;
  int endOfGetFunctions = -1;
  int endOfGetOnlyFunctions = -1;
  int endOfSetOnlyFunctions = -1;
  int endOfGetAndSetFunctions = -1;
  int endOfProtectedFunctions = -1;
  int indentation = 0;
  int designator;
  /* array to store indices of the data->Functions array that are
   * functions starting with "Add" */
  int addFunctions[MAX_ARRAY_SIZE];
  int setFunctions[MAX_ARRAY_SIZE];
  int removeFunctions[MAX_ARRAY_SIZE];
  int getFunctions[MAX_ARRAY_SIZE];
  int setOnlyFunctions[MAX_ARRAY_SIZE];
  int getOnlyFunctions[MAX_ARRAY_SIZE];
  int getAndSetFunctions[MAX_ARRAY_SIZE];
  int protectedFunctions[MAX_ARRAY_SIZE];

  /* separate functions into functions beginning with "Add", "Remove",
   * "Set", and "Get" here */
  separateFunctions(fp, data,
    addFunctions, &endOfAddFunctions, removeFunctions, &endOfRemoveFunctions,
    setFunctions, &endOfSetFunctions, getFunctions, &endOfGetFunctions,
    protectedFunctions, &endOfProtectedFunctions); 

  /* categorize the Set/Get functions as follows: values with "Set"
   * only, values with "Get" only, and values with "Set" and "Get". */
  categorizeSetGetFunctions(fp, data,
    getFunctions, &endOfGetFunctions, setFunctions, &endOfSetFunctions,
    setOnlyFunctions, &endOfSetOnlyFunctions,
    getOnlyFunctions, &endOfGetOnlyFunctions,
    getAndSetFunctions, &endOfGetAndSetFunctions);

  /* take only methods with both an add and remove method and place
   * in 'add' array. */
  checkMatchBetweenAddAndRemoveList(fp, data,
    removeFunctions, &endOfRemoveFunctions, 6,
    addFunctions, &endOfAddFunctions, 3);

  /* remove all unwanted functions from the list (ie. those that may have
   * gotten by with duplicate names or those that have mixed arguments that
   * aren't indexed type) */
  removeBadFunctions(data, setOnlyFunctions, &endOfSetOnlyFunctions);
  removeBadFunctions(data, getAndSetFunctions, &endOfGetAndSetFunctions);

  removeDuplicateFunctions(data, setOnlyFunctions, &endOfSetOnlyFunctions);
  removeDuplicateFunctions(data, getOnlyFunctions, &endOfGetOnlyFunctions);
  removeDuplicateFunctions(data, getAndSetFunctions, &endOfGetAndSetFunctions);

  /* 
  for (i = 0; i < endOfGetAndSetFunctions; i++)
    {
    printf("%s after\n", data->Functions[getAndSetFunctions[i]].Name);
    }
    printf("%i = setOnly\n", endOfSetOnlyFunctions);
    printf("%i = getOnly\n", endOfGetOnlyFunctions);
    printf("%i = setget\n", endOfGetAndSetFunctions);
  */

  /* sort function index lists based on alphabetical order of corresponding
   * function name in data */
  sortByName(data, addFunctions, 0, endOfAddFunctions);
  sortByName(data, setOnlyFunctions, 0, endOfSetOnlyFunctions);
  sortByName(data, getOnlyFunctions, 0, endOfGetOnlyFunctions);
  sortByName(data, getAndSetFunctions, 0, endOfGetAndSetFunctions);
  sortByName(data, protectedFunctions, 0, endOfProtectedFunctions);

  /* get Functions starting with "Get" that have no
   * corresponding "Set" function to be used as promoters. */
  getPromotedOutputs(fp, data, getFunctions, &endOfGetFunctions,
                     getAndSetFunctions, &endOfGetAndSetFunctions);

  /* start new XML filter section for class */

  indent(fp, indentation);
  fprintf(fp, "<Filter>\n");
  indentation++;
  /* write the header of the file */
  indent(fp, indentation);
  fprintf(fp, "<Filter_Name>%s</Filter_Name>\n", data->ClassName);
  indent(fp, indentation);
  fprintf(fp, "<Filter_Abstract_Flag>%i</Filter_Abstract_Flag>\n",
          data->IsAbstract);
  if (data->NumberOfSuperClasses > 0)
    {
    indent(fp, indentation);
    fprintf(fp, "<Super_Class>%s</Super_Class>\n", data->SuperClasses[0]);
    }

  /* print the documentation */
  ClassDocumentation(fp, data, indentation);

  /* function handling code 
   * First one is to list all inputs that come from the add,
   * remove functions.*/
  for (i = 0; i <= endOfAddFunctions; i++)
    {
    InputFunctions(fp, &data->Functions[addFunctions[i]], indentation);
    }
  /* for addinng all the set functions that take vtkObjects as arguments,
   * which have been promoted to inputs */
  for (i = 0; i <= endOfGetAndSetFunctions; i++)
    {
    InputFunctions(fp, &data->Functions[getAndSetFunctions[i]], indentation);
    }
  for (i = 0; i <= endOfSetOnlyFunctions; i++)
    {
    InputFunctions(fp, &data->Functions[setOnlyFunctions[i]], indentation);
    }

  /* All inputs should be added now, so only need to add parameters */
  /* add all parameters to the XML file */
  indent(fp, indentation);
  fprintf(fp, "<Filter_Parameters>\n");
  indentation++;
  for (i = 0; i <= endOfSetOnlyFunctions; i++)
    {
    /* used to know what Parameter_Tag to print, 0 will be for Set only */
    designator = 0;
    ParameterFunctions(fp, &data->Functions[setOnlyFunctions[i]],
                       indentation, designator);
    }
  for (i = 0; i <= endOfGetOnlyFunctions; i++)
    {
    /* used to know what Parameter_Tag to print, 1 will be for Get only */
    designator = 1;
    ParameterFunctions(fp, &data->Functions[getOnlyFunctions[i]],
                       indentation, designator);
    }
  for (i = 0; i <= endOfGetAndSetFunctions; i++)
    {
    /* used to know what Parameter_Tag to print, 2 will be for Both */
    designator = 2;
    ParameterFunctions(fp, &data->Functions[getAndSetFunctions[i]],
                       indentation, designator);
    }
  indentation--;
  indent(fp, indentation);
  fprintf(fp, "</Filter_Parameters>\n");
  sortByName(data, getFunctions, 0, endOfGetFunctions);
  /* print all promoted outputs in alphabetical order. */
  for (i = 0; i <= endOfGetFunctions; i++)
    {
    PrintOutput(fp, data->Functions[getFunctions[i]].Name+3,
                data->Functions[getFunctions[i]].ReturnClass, indentation);
    }
  /* print a list of all protected functions.  Only need to list the name
   * as will only be used to check against to make sure not to add if is
   * found in parent class */
  for (i = 0; i <= endOfProtectedFunctions; i++)
    { 
    PrintProtectedFunctions(fp, data->Functions[protectedFunctions[i]].Name,
                            indentation);
    }
  /* PrintOutput(fp, "Self", data->ClassName, indentation); */
  indentation--;
  indent(fp, indentation);
  fprintf(fp, "</Filter>\n");
}
