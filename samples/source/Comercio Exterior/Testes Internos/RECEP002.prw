#include "Protheus.ch"            
#INCLUDE "FWADAPTEREAI.CH"
#INCLUDE "Average.ch"

/*
Funcao    : MenuDef()
Parametros: Nenhum
Objetivos : Tornar a rotina pass�vel de ser cadastrada como Adapter no Configurador
Autor     : Nilson C�sar
Data/Hora : 14/04/2016
Revisao   : 
Obs.      :
*/
//=========================
  Static Function MenuDef()
//=========================

Return {}


/*
Funcao    : IntegDef()
Parametros: Par�metros recebidos do EAI-Protheus
Objetivos : Simular a recep��o e resposta do Logix para a mensagem �nica de: Cota��o de Pre�o
Autor     : Nilson C�sar
Data/Hora : 14/04/2016
Revisao   : 
Obs.      :
*/
//========================================================
  Static Function IntegDef(cXML, nTypeTrans, cTypeMessage)
//========================================================
Local cXMLRet    := ""
Local lRet       := .T.
Local cXMLRetGrv := ""
Local oEasyIntEAI   := EasyIntEAI():New(cXML, nTypeTrans, cTypeMessage)
Local oBusinessCont := oEasyIntEAI:oMessage:GetMsgContent()
Local nI,nJ,nX
Local lRet := .T.
Local cCod, cNum
Local cCodRqAtu := ""
Local cCodItAtu := ""
Local aStatus := { {"1","Normal"} , ;
	                {"2","Bloqueado"} , ;
	                {"3","Liberado"} , ;
	                {"4","Liberado Financeiro"},;
	                {"5","Liberado Financeiro e Comercial"},;
	                {"6","Suspenso"},;
	                {"7","Cancelado"}}
Varinfo("cXML",cXML)
Varinfo("nTypeTrans",nTypeTrans)
Varinfo("cTypeMessage",cTypeMessage)


If nTypeTrans == TRANS_RECEIVE
   If cTypeMessage <> EAI_MESSAGE_WHOIS
   
      oItens:=oBusinessCont:_SALESORDERITENS

      If ValType(oItens) <> "A"
         aItens:= {oItens}
      Else
         aItens := oItens
      EndIf
   
      lDelete := UPPER( oEasyIntEAI:oMessage:CBSNEVENT ) == "DELETE"
      lAltera := .T. 
      
      If ValType(oEasyIntEAI:oMessage:oXML:_TOTVSMESSAGE:_BUSINESSMESSAGE:_BUSINESSEVENT:_IDENTIFICATION:_KEY) == "O"
         cNum := "["+Alltrim(oEasyIntEAI:oMessage:oXML:_TOTVSMESSAGE:_BUSINESSMESSAGE:_BUSINESSEVENT:_IDENTIFICATION:_KEY:TEXT)+"]" //"&["+Alltrim(cCodItAtu)+"]&["+ +"]"  )// N�o pegar o caracter "|"
      EndIf
                       
      If !Empty(cNum) 
         If !File("02RSPORDERS\"+cNum+".txt")
            If !lDelete
               cIdInt := Alltrim(StrZero(Val(GETSX8NUM("SW2","W2_PO_SIGA")),AVSX3("W2_PO_SIGA",AV_TAMANHO))) //Tamanho do WT_NUMERP na Origem
               ConfirmSX8()
               aTit := {"1",cIdInt}
               MemoWrite("02RSPORDERS\"+cNum+".txt", StrMerge(aTit))
               cXMLRetGrv += '<OrderId>'+cIdInt+'</OrderId><Status>'+aStatus[1][1]+'</Status>'
            Else
               lRet  := .F.
               cErro := "Pedido n�o existe."
            EndIf
         Else 
            If lDelete
               FErase("02RSPORDERS\"+cNum+".txt")
            ElseIf !lAltera
               lRet  := .F.
               cErro := "O registro: "+cNum+" j� existe e n�o pode ser alterado no destino!"            
            EndIf
            //altera��o retorna o n�mero do Pedido e o status bloqueado (enviar a Order de Aprova��o posteriormente)
            aTit := EasyStrSplit(MemoRead("02RSPORDERS\"+cNum+".txt"),";")
            cXMLRetGrv += '<OrderId>'+aTit[2]+'</OrderId><Status>'+aStatus[1][1]+'</Status>'
         EndIf
       Else
          lRet  := .F.
          cErro := "N�o foi poss�vel gravar o arquivo do registro no destino pois o cod. do Pedido no ERP Origem n�o foi informado corretamente na mensagem �nica!"        
       EndIf  
      
   EndIf

   //for�ar erro de integra��o para testes
   //lRet := .F.
   //cErro:= "Retorno de Erro Para testes - Integra�ao de Ordem de Compra - ORDER - [XX4=RECEP002]"
   
   If lRet
      If cTypeMessage == EAI_MESSAGE_BUSINESS
         cXMLRet := cXMLRetGrv
   	  ElseIf cTypeMessage == EAI_MESSAGE_RESPONSE
         cXMLRet := cXMLRetGrv   
      ElseIf   cTypeMessage == EAI_MESSAGE_WHOIS
         cXMLRet := '3.003'
	  EndIf
   Else
      cXMLRet := "<Error>"+cErro+"</Error>"
   EndIf
ElseIf nTypeTrans == TRANS_SEND
	cXMLRet := '<BusinessMessage><BusinessRequest><Operation>LGEIC1410</Operation></BusinessRequest><BusinessContent></BusinessContent></BusinessMessage>'
EndIf

Varinfo("IntegDef_Return",{ lRet, cXMLRet })
Return { lRet, cXMLRet }


/*
Funcao    : EasyStrSplit()
Parametros: cString    -> String a quebar em array
            cSeparator -> String que separa os dados na String
Objetivos : Converter informa��o disposta em String literal em array
Autor     : Alessandro Alves Ferreira
Data/Hora : 
Revisao   : 
Obs.      :
*/
//=================================================
   Static Function EasyStrSplit(cString,cSeparador)
//=================================================
Local aRet := {}
Local cAux := ""
Local nPos

If ValType(cString) == "C" .AND. !Empty(cString) .AND. ValType(cSeparador) == "C"
   Do While (nPos := At(cSeparador , cString)) <> 0
      aAdd(aRet,SubStr(cString,1,nPos-1))
      cString := SubStr(cString,nPos+1,Len(cString))
   EndDo
   aAdd(aRet,cString)
EndIf

Return aRet

Static Function StrMerge(aStr)
Local i
Local cRet := ""
For i := 1 To Len(aStr)
   cRet += aStr[i]+";"
Next i
Return Left(cRet,Len(cRet)-1)
