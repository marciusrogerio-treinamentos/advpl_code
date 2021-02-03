#include "Protheus.ch"            
#INCLUDE "FWADAPTEREAI.CH"
//AccountingEntry_1_000
Static Function MenuDef()
Return {}

User Function IntegT2()
RpcSetType(3)
RpcSetEnv("99","01")

WSAdvValue( oXmlRet,"_SENDMESSAGERESPONSE:_SENDMESSAGERESULT:TEXT","base64Binary",NIL,NIL,NIL,NIL,NIL,NIL) 

Return EnvEAI("CONINEXCTB")

Static Function integdef(cXML, nTypeTrans, cTypeMessage)
Local cXMLRet := ""
Local lRet := .T.
Local cError := "", cWarning := ""
Local i

Varinfo("cXML",cXML)
Varinfo("nTypeTrans",nTypeTrans)
Varinfo("cTypeMessage",cTypeMessage) 

//forçar erro de integração para testes
//lRet := .F.
//cErro:= "Retorno de Erro Para testes - Integraçao da Variação cambial - AccountEntry - EECAF224 - TESTEXML2"

If nTypeTrans == TRANS_RECEIVE 
    IF !Empty(cXML) .And. lRet 
	
	   If !(oXML := XmlParser(cXML, "_", @cError, @cWarning),ValType(oXML) == "O" .AND. Empty(cError))
	      lRet := .F.
		  cErro := "Não foi possivel interpretar XML: "+cError
	   Else
		   lAltera := .F.
		   lDelete := AllTrim(Upper(GetXMLInfo(cXML, "Event"))) == "DELETE"
		   
		   cNum := GetXMLInfo(cXML, "BatchNumber")
		   If !lDelete .AND. Empty(cNum)
			  cNum := AllTrim(Str(Val(GETSX8NUM("ECF","ECF_LOTERP"))))
			  ConfirmSX8()
		   Endif
		   
		   If ValType(oXML:_TOTVSMESSAGE:_BUSINESSMESSAGE:_BUSINESSCONTENT:_Entries:_Entry) <> "A"
	          aArray := {oXML:_TOTVSMESSAGE:_BUSINESSMESSAGE:_BUSINESSCONTENT:_Entries:_Entry}
	       Else
	          aArray := oXML:_TOTVSMESSAGE:_BUSINESSMESSAGE:_BUSINESSCONTENT:_Entries:_Entry
	       EndIf
		   
		   If lDelete
		      aTit := EasyStrSplit(MemoRead("05RSPCON\"+cNum+".txt"),";")
			  If Len(aTit) <> Len(aArray)
			     lRet := .F.
				 cErro:= "Diferenças entre lançamentos para estorno e lançamentos do lote "+cNum
			  EndIf
		   Else
		      aTit := {}
		   EndIf
		   
		   cEntrys := ""
		   For i := 1 To Len(aArray)
		      
			  If lDelete
			     nPos := aScan(aTit,{|X| AllTrim(X) == AllTrim(aArray[i]:_EntryNumber:TEXT)+"|"+AllTrim(aArray[i]:_RelationshipNumber:TEXT)})
				 If nPos == 0
				    lRet := .F.
					cErro:= "Lançamento "+AllTrim(aArray[i]:_EntryNumber:TEXT)+"|"+AllTrim(aArray[i]:_RelationshipNumber:TEXT)+ " não encontrado para estorno."
					EXIT
				 Else
				    cRelNum := AllTrim(aArray[i]:_RelationshipNumber:TEXT)
				    aTit[nPos] := " "
				 EndIf
			  Else
			     aAdd(aTit,aArray[i]:_EntryNumber:TEXT+"|"+(cRelNum:= AllTrim(Str(Val(GETSX8NUM("ECF","ECF_RELACAM"))))))
			     ConfirmSX8()
			  EndIf
			  
			  cEntrys += '<Entry><EntryNumber>'+aArray[i]:_EntryNumber:TEXT+'</EntryNumber><RelationshipNumber>'+cRelNum+'</RelationshipNumber></Entry>'
		   Next i
	       
	       If lRet
		   If !File("05RSPCON\"+cNum+".txt")
			  If !lDelete
				 MemoWrite("05RSPCON\"+cNum+".txt", StrMerge(aTit))
			  Else
				 lRet  := .F.
				 cErro := "Lote não existe."
			  EndIf
		   Else
			  If !lDelete
				 If lAltera
			        MemoWrite("05RSPCON\"+cNum+".txt", StrMerge(aTit))
				 Else
				    lRet  := .F.
				    cErro := "Alteracoes de lote nao sao permitidas."
				 EndIf
			  Else
				 FErase("05RSPCON\"+cNum+".txt")
			  EndIf
		   EndIf
		   EndIf
	   EndIf
    EndIf
    
    If lRet
		If cTypeMessage == EAI_MESSAGE_BUSINESS
			cXMLRet := '<BatchNumber>'+cNum+'</BatchNumber><Entries>'+cEntrys+'</Entries>' 
		ElseIf cTypeMessage == EAI_MESSAGE_RESPONSE
			cXMLRet := '<BatchNumber></BatchNumber><Entries><Entry><EntryNumber></EntryNumber><RelationshipNumber></RelationshipNumber></Entry><Entry><EntryNumber></EntryNumber><RelationshipNumber></RelationshipNumber></Entry></Entries>' 
		ElseIf   cTypeMessage == EAI_MESSAGE_WHOIS
			cXMLRet := '1.000'
		EndIf
    Else
       cXMLRet := "<Error>"+cErro+"</Error>"
	EndIf
ElseIf nTypeTrans == TRANS_SEND
	cXMLRet := '<BusinessMessage><BusinessRequest><Operation>EECAF227</Operation></BusinessRequest><BusinessContent><CompanyId>99</CompanyId><BranchId>01</BranchId><DocumentPrefix>EEC</DocumentPrefix><DocumentNumber>388</DocumentNumber><DocumentParcel>1'
	cXMLRet += '</DocumentParcel><DocumentTypeCode>XP</DocumentTypeCode><PaymentDate>2012-02-15</PaymentDate><CreditDate>2012-02-15</CreditDate><EntryDate>2012-02-15</EntryDate><PaymentValue>25</PaymentValue><CurrencyRate>1.81546</CurrencyRate><CustomerCode>1'
	cXMLRet += '</CustomerCode><StoreId>.</StoreId><PaymentMethod>004</PaymentMethod><PaymentMeans>000</PaymentMeans><HolderCode>900</HolderCode><HolderType>C</HolderType><FinancialCode></FinancialCode><ListOfCreditDocument><CreditDocument><CompanyId>99'
	cXMLRet += '</CompanyId><BranchId>01</BranchId><DocumentPrefix>EEC</DocumentPrefix><DocumentNumber>26</DocumentNumber><DocumentParcel>2</DocumentParcel><DocumentTypeCode>TC</DocumentTypeCode><CustomerCode>1</CustomerCode><StoreId>.</StoreId>'
	cXMLRet += '<DocumentValue>25</DocumentValue></CreditDocument></ListOfCreditDocument><DischargeSequence>5</DischargeSequence></BusinessContent></BusinessMessage>'
EndIf

Varinfo("IntegDef_Return",{ lRet, cXMLRet })
Return { lRet, cXMLRet }

*---------------------------------------------------------*
Static Function EnvEAI(cFuncName) 
*---------------------------------------------------------*
Local aArea       := GetArea()
Local aAreaXX4    := XX4->( GetArea() )
Local nTamFunName := Len( cFuncName ) 
Local aRetorno    := {}

EvalTrigger()
/*
If FindFunction( 'FWXX4SEEK' )
	XX4->( dbSetOrder( 1 ) )
	XX4->( MsSeek(PadR(xFilial('XX4'),Len(XX4->XX4_FILIAL) ) + cFuncName ) )
	FWXX4Seek( cFuncName )
	conOut("teste2")
	While !XX4->( EOF() ) .AND. cFuncName == SubStr( XX4->XX4_ROTINA, 1, nTamFunName )
	    conOut("teste3")
		If FWEAICanSend( EAI_MESSAGE_BUSINESS,, cFuncName )
		   conOut("teste4")
		   aRetorno := &( "STATICCALL(" + cFuncName + ", IntegDef, NIL, '" + TRANS_SEND + "', '" + EAI_MESSAGE_BUSINESS + "')")
			VarInfo("aRetorno",aRetorno)
			If ValType( aRetorno ) == 'A' .AND. Len( aRetorno ) > 1 .AND. aRetorno[1]
				FWEAIMake( EAI_MESSAGE_RESPONSE, aRetorno[2] )
			EndIf
		EndIf
		XX4->( dbSkip() )
	End
EndIf
*/

RestArea( aAreaXX4 )
RestArea( aArea )

Return .T.


Static Function GetXMLInfo(cXML, cTag)
Local nPos
Local cRet := ""

nPos := At("<"+Upper(cTag)+">",Upper(cXML))+Len("<"+Upper(cTag)+">")

If nPos > Len("<"+Upper(cTag)+">")
   nPos2:= At("</"+Upper(cTag)+">",Upper(cXML),nPos)
   If nPos2 > 0
      cRet := SubStr(cXML,nPos,nPos2-nPos)
   EndIf
EndIf

Return cRet

Static Function EasyStrSplit(cString,cSeparador)
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