#include "Protheus.ch"            
#INCLUDE "FWADAPTEREAI.CH"
#INCLUDE "Average.ch"

/*
Funcao    : MenuDef()
Parametros: Nenhum
Objetivos : Tornar a rotina passível de ser cadastrada como Adapter no Configurador
Autor     : Nilson César
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
Parametros: Parâmetros recebidos do EAI-Protheus
Objetivos : Simular a recepção e resposta do Logix para a mensagem única de: Titulos Provisorios (Pagar)
Autor     : Nilson César
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
   
      lDelete := UPPER( oEasyIntEAI:oMessage:CBSNEVENT ) == "DELETE"
      
      IF VALTYPE(oBusinessCont:_LISTOFACCOUNTPAYABLEDOCUMENT:_ACCOUNTPAYABLEDOCUMENT) <> "A"
         aPayableDoc := {oBusinessCont:_LISTOFACCOUNTPAYABLEDOCUMENT:_ACCOUNTPAYABLEDOCUMENT}
      ELSE 
         aPayableDoc := oBusinessCont:_LISTOFACCOUNTPAYABLEDOCUMENT:_ACCOUNTPAYABLEDOCUMENT
      ENDIF

      For nJ:=1 to len(aPayableDoc)
      
	     cNum := EasyGetXMLinfo(,aPayableDoc[nJ], "_DocumentNumber" )
		 
         If !lDelete .AND. Empty(cNum)
            cNum := GETSX8NUM("SE2","E2_NUM")//Alltrim(StrZero(Val(GETSX8NUM("SE2","E2_NUM")),AVSX3("E2_NUM",AV_TAMANHO)))
            ConfirmSX8()
         Endif
       
         If !File("03RSPCAP\"+cNum+".txt")
            If !lDelete
               aTit := {"1",EasyGetXMLinfo(,aPayableDoc[nJ], "_NetValue" )}
               MemoWrite("03RSPCAP\"+cNum+".txt", StrMerge(aTit))
               cXMLRetGrv += '<InternalIdDocument>'+;
                                '<Name></Name>'+;
                                '<Origin>'+EasyGetXMLinfo(,aPayableDoc[nJ], "_InternalId" )+'</Origin>'+;
                                '<Destination>'+cNum+'</Destination>'+;
                                '<Value>'+Str( Val(aTit[2]),AvSx3("E2_VALOR",AV_TAMANHO),AvSx3("E2_VALOR",AV_DECIMAL) )+'</Value>'+;
                             '</InternalIdDocument>'
            Else
               lRet  := .F.
               cErro := "Titulo não existe."
            EndIf
         Else
            aTit  := EasyStrSplit(MemoRead("03RSPCAP\"+cNum+".txt"),";")
            lBaixado := aTit[1] == "3"
            lAltera := .T.    //NCF - 08/08/2014 - Permitir alteração para teste 
            If !lBaixado
               If !lDelete
                  If ValType(lAltera) == "L" .And. lAltera
                     aTit := {"2",EasyGetXMLinfo(,aPayableDoc[nJ], "_NetValue" )}
                     MemoWrite("03RSPCAP\"+cNum+".txt", StrMerge(aTit))
                     cXMLRetGrv += '<InternalIdDocument>'+;
                                      '<Name></Name>'+;
                                      '<Origin>'+EasyGetXMLinfo(,aPayableDoc[nJ], "_InternalId" )+'</Origin>'+;
                                      '<Destination>'+cNum+'</Destination>'+;
                                      '<Value>'+Str( Val(aTit[2]),AvSx3("E2_VALOR",AV_TAMANHO),AvSx3("E2_VALOR",AV_DECIMAL) )+'</Value>'+;
                                   '</InternalIdDocument>'                     
                  Else
                     lRet  := .F.
                     cErro := "Alteracoes de titulo a pagar nao sao permitidas."
                  EndIf
               Else
                  aTit := {"2",EasyGetXMLinfo(,aPayableDoc[nJ], "_NetValue" )}
                  cXMLRetGrv += '<InternalIdDocument>'+;
                                      '<Name></Name>'+;
                                      '<Origin>'+EasyGetXMLinfo(,aPayableDoc[nJ], "_InternalId" )+'</Origin>'+;
                                      '<Destination>'+cNum+'</Destination>'+;
                                      '<Value>'+Str( Val(aTit[2]),AvSx3("E2_VALOR",AV_TAMANHO),AvSx3("E2_VALOR",AV_DECIMAL) )+'</Value>'+;
                                   '</InternalIdDocument>' 
                  FErase("03RSPCAP\"+cNum+".txt")
               EndIf
            Else
               lRet  := .F.
               cErro := If(lDelete,"Titulo não pode ser excluido pois esta baixado.","Titulo baixado nao pode ser alterado.")
            EndIf
         EndIf
     
      Next nJ
      
   EndIf

   //forçar erro de integração para testes
   //lRet := .F.
   //cErro:= "Retorno de Erro Para testes - Integraçao de TÍTULOS A PAGAR - LISTOFACCOUNTPAYABLEDOCUMENT - [XX4=RECEP003]"
   
   If lRet
      If cTypeMessage == EAI_MESSAGE_BUSINESS
         cXMLRet := '<ListOfInternalIdDocument>' + cXMLRetGrv + '</ListOfInternalIdDocument>'
   	  ElseIf cTypeMessage == EAI_MESSAGE_RESPONSE
         cXMLRet := cXMLRetGrv   
      ElseIf   cTypeMessage == EAI_MESSAGE_WHOIS
         cXMLRet := '1.000'
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
Objetivos : Converter informação disposta em String literal em array
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
