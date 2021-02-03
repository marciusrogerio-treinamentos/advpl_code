   
 //ExecAuto na rotina de SI
*-------------------------*
User Function DespExecAuto()
*-------------------------*

Local    aTit:={}
Local    aDesembaraco := {}  // desembaraço
Private  aDespesas := {} // despesas
Private  aItem:= {}
Private  lMsErroAuto := .F.

  
   aDesembaraco := {"W6_HAWB","10100            "   ,NIL}
   aDespesas := {}
   aTit:={}
  

  
  
  // inclui
  aAdd(aItem,{  {"WD_DESPESA"   ,  "409",NIL},;
              {"WD_DES_ADI"    ,  dDataBase        ,NIL},;          
              {"WD_VALOR_R"    ,  30,00       ,NIL},;
              {"WD_BASEADI"    ,  "1"        ,NIL},;
             {"WD_PAGOPOR"   ,  "1"     ,NIL}})   
             
        
             
                                                 
// altera  
  aAdd(aItem,{  {"WD_DESPESA"   ,  "409",NIL},;
              {"WD_DES_ADI"    ,  dDataBase        ,NIL},; 
              {"WD_VALOR_R"  ,  999,00             ,NIL},;
              {"WD_HAWB"   ,  "10100            "    ,NIL}}) 
  


// deleta uma despesa 
  aAdd(aItem,{  {"WD_DESPESA"   ,  "409",NIL},;
              {"WD_HAWB"   ,  "10100            "    ,NIL},;
              {"WD_DES_ADI"    ,  dDataBase        ,NIL},; 
              {"AUTDELETA"  ,  "S"             ,NIL}}) 
                                                          


  // inclui
  aAdd(aItem,{  {"WD_DESPESA"   ,  "407",NIL},;
              {"WD_DES_ADI"    ,  dDataBase        ,NIL},;          
              {"WD_VALOR_R"    ,  95,00       ,NIL},;
              {"WD_BASEADI"    ,  "1"        ,NIL},;
             {"WD_PAGOPOR"   ,  "1"     ,NIL}})       
  
// deleta uma despesa 
/*  aAdd(aItem,{  {"WD_DESPESA"   ,  "407",NIL},;
              {"WD_HAWB"   ,  "10100            "    ,NIL},;
              {"WD_DES_ADI"    ,  dDataBase        ,NIL},; 
              {"AUTDELETA"  ,  "S"             ,NIL}})    
*/
 

   
   

   
   
   lMsErroAuto:=.F.
   lRetF050   :=.T.
   MSExecAuto({|a,b,c,d,e| DI500Main(a,b,c,d,e)},,, aDesembaraco,aItem, 7 )
                                                      

If lMsErroAuto
   MOSTRAERRO()
Else
   MsgInfo("Despesas Criadas com sucesso!")
EndIf      
//EndIf         

Return .T.


*-----------------------------------*
Static Function EasyHelp(cText,cTit)
*-----------------------------------*
Local cHelpTit  := StrTran(cTit ,Chr(13)+Chr(10)," ")//"##TITULO##"
Local cHelpText := StrTran(cText,Chr(13)+Chr(10)," ")//"##"+Repl("A",10)+Repl(Chr(13)+Chr(10),20)+"##"

Help("",1,"AVG",cHelpTit,cHelpText,1,0,.F.)

Return Nil


/*   



MSExecAuto({|a,b,c,d| EICSI400(a,b,c)},aCab,aItem,4)
  */

