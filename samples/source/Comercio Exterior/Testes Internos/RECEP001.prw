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
Objetivos : Simular a recepção e resposta do Logix para a mensagem única de: Cotação de Preço
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
Local cProposId := ""
Varinfo("cXML",cXML)
Varinfo("nTypeTrans",nTypeTrans)
Varinfo("cTypeMessage",cTypeMessage)


If nTypeTrans == TRANS_RECEIVE
   If cTypeMessage <> EAI_MESSAGE_WHOIS
      oItens:=oBusinessCont:_ListOfQuotationItem:_QUOTATIONITEM

      If ValType(oItens) <> "A"
         aItens:= {oItens}
      Else
         aItens := oItens
      EndIf
   
      lDelete := UPPER( oEasyIntEAI:oMessage:CBSNEVENT ) == "DELETE"
      lAltera := .T.   
          
      For nI:=1 to len(aItens) 

         cCodRqAtu :=  aItens[nI]:_REQUESTCODE:TEXT                  //Requisição de Compra (SI)
         cCodItAtu :=  aItens[nI]:_ITEMCODE:TEXT                     //Item 
   
         IF VALTYPE(aItens[nI]:_LISTOFQUOTATIONPROPOSAL:_QUOTATIONPROPOSAL) <> "A"
            aProposal := {aItens[nI]:_LISTOFQUOTATIONPROPOSAL:_QUOTATIONPROPOSAL}
         ELSE 
            aProposal := aItens[nI]:_LISTOFQUOTATIONPROPOSAL:_QUOTATIONPROPOSAL
         ENDIF

         For nJ:=1 to len(aProposal)
            
            cNum := UPPER( "["+Alltrim(cCodRqAtu)+"]&["+Alltrim(cCodItAtu)+"]&["+ StrTran( aProposal[nJ]:_ProposalInternalId:TEXT , "|", "_" ,,)+"]"  )// Não pegar o caracter "|"
            cProposId := aProposal[nJ]:_ProposalInternalId:TEXT
                       
            If !File("01RSPQUOTATIONS\"+cNum+".txt")
               If !lDelete
                  cIdInt := "||" + Alltrim(StrZero(Val(GETSX8NUM("SWT","WT_ID")),6)) + "|" + SUBSTR(cProposId, AT("|",cProposId)+1 ,len(cProposId)) /*Right( cProposId, 3)*/ //Tamanho do WT_NUMERP na Origem
                  ConfirmSX8()
                  aTit := {"1",cIdInt}
                  MemoWrite("01RSPQUOTATIONS\"+cNum+".txt", StrMerge(aTit))
                  cXMLRetGrv += '<InternalId><Origin>'+StrTran( cProposId , "_", "|"  )+'</Origin><Destination>'+cIdInt+'</Destination></InternalId>
               Else
                  lRet  := .F.
                  cErro := "Cotacao não existe."
               EndIf
            Else
               aTit  := EasyStrSplit(MemoRead("01RSPQUOTATIONS\"+cNum+".txt"),";")
               lFinalizado := aTit[1] == "3"
          
               If !lFinalizado
                  If !lDelete
                     If lAltera
                        aTit := {"2",aTit[2]}
                        MemoWrite("01RSPQUOTATIONS\"+cNum+".txt", StrMerge(aTit))
                        cXMLRetGrv += '<InternalId><Origin>'+StrTran( aProposal[nJ]:_ProposalInternalId:TEXT, "_", "|"  )+'</Origin><Destination>'+aTit[2]+'</Destination></InternalId>
                     Else
                        lRet  := .F.
                        cErro := "Alteracoes de cotacao nao sao permitidas."
                     EndIf
                  Else
                     FErase("01RSPQUOTATIONS\"+cNum+".txt")
                  EndIf
               Else
                  lRet  := .F.
                  cErro := If(lDelete,"Cotacao não pode ser excluido pois esta finalizada.","Cotacao finalizada nao pode ser alterada.")
               EndIf
            EndIf    
         Next
      Next
   EndIf

   //forçar erro de integração para testes
   //lRet := .F.
   //cErro:= "Retorno de Erro Para testes - Integraçao de Cotaçao de Preços - QUOTATION - [XX4=RECEP001]"
   
   If lRet
      If cTypeMessage == EAI_MESSAGE_BUSINESS
         cXMLRet := '<ListOfInternalId>'+cXMLRetGrv+'</ListOfInternalId>'
   	  ElseIf cTypeMessage == EAI_MESSAGE_RESPONSE
         cXMLRet := '<ListOfInternalId>'+cXMLRetGrv+'</ListOfInternalId>'   
      ElseIf   cTypeMessage == EAI_MESSAGE_WHOIS
         cXMLRet := '1.002'
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
