#Include 'PROTHEUS.CH'
#Include 'XMLXFUN.CH'
//-------------------------------------------------------------------
/*/{Protheus.doc} NFEspNeo
RDMake para geracao do XML do envio de Espelho de Nota Fiscal.

@sample 	NFEspNeo()

@author		Leonardo Kichitaro
@since		18/04/2015
@version	P11.8
/*/
//-------------------------------------------------------------------
User Function NFEspNeo(cXml,cSerie,cNota,cClieFor,cLoja)

Local cString	:= ""
Local cCFOP		:= ""
Local cContrato	:= ""
Local cContrSC5	:= ""
Local cContrSC6	:= ""
Local cItemSC6	:= ""
Local cPedCli	:= ""
Local cCnpj		:= ""
Local cAliasSD2	:= "SD2"

Local nX		:= 0
Local nPercPgto	:= 0

Local aNota		:= {}
Local aProd		:= {}
Local aPgto		:= {}

Default cXml		:= PARAMIXB[1]
Default cSerie		:= PARAMIXB[2]
Default cNota		:= PARAMIXB[3]
Default cClieFor	:= PARAMIXB[4]
Default cLoja		:= PARAMIXB[5]    

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Posiciona NF                                                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea("SF2")
dbSetOrder(1)
If MsSeek(xFilial("SF2")+cNota+cSerie+cClieFor+cLoja)
	// Busca CFOP
	dbSelectArea("SF3")
	SF3->(dbSetOrder(4))
	If MsSeek(xFilial("SF3")+SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_DOC+SF2->F2_SERIE)
		cCFOP := SF3->F3_CFO
	EndIf

	If !SF2->F2_TIPO $ "DB"
		MsSeek(xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA)
		cCnpj := AllTrim(SA1->A1_CGC)
	Else
		MsSeek(xFilial("SA2")+SF2->F2_CLIENTE+SF2->F2_LOJA)
		cCnpj := AllTrim(SA2->A2_CGC)
	EndIf
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Pesquisa numero do contrato                                             ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	SC5->(dbSetOrder(1))
	SC6->(dbSetOrder(4))
	SC6->(MsSeek(xFilial("SC6")+SF2->F2_DOC+SF2->F2_SERIE))	//C6_FILIAL+C6_NOTA+C6_SERIE
	While !SC6->( Eof() ) .And. SC6->( C6_FILIAL+C6_NOTA+C6_SERIE ) == xFilial("SC6")+SF2->F2_DOC+SF2->F2_SERIE
		cContrato := Iif(Empty(cContrato),SC6->C6_PEDCLI,cContrato)
		SC5->(MsSeek(xFilial("SC5")+SC6->C6_NUM))
		cContrSC5 := SC5->C5_CONTRA
		If SC6->C6_PEDCLI <> cContrato
			cContrato := ""
			Exit
		EndIf

		SC6->( dbSkip() )
	EndDo

	//Array para envio da Tag HEADER ... Caso necessario definir mais informacoes nessa array
	aadd(aNota,SF2->F2_SERIE)
	aadd(aNota,SF2->F2_DOC)
	aadd(aNota,cCFOP)
	aadd(aNota,AllTrim(cContrato))
	aadd(aNota,AllTrim(cContrSC5))
	aadd(aNota,cCnpj)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Busca títulos gerados                                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SE1")
	SE1->(dbSetOrder(2))
	If SE1->(dbSeek(xFilial("SE1")+SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_SERIE+SF2->F2_DOC))
		While !SE1->(Eof()) .And. xFilial("SE1") == SE1->E1_FILIAL .And.;
				SF2->F2_CLIENTE == SE1->E1_CLIENTE .And. SF2->F2_LOJA == SE1->E1_LOJA .And.;
				SF2->F2_SERIE == SE1->E1_PREFIXO .And. SF2->F2_DOC == SE1->E1_NUM

				If 'NF' $ SE1->E1_TIPO
					aadd(aPgto,{SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_EMISSAO,SE1->E1_VENCTO,SE1->E1_VALOR,SF2->F2_COND})
				EndIf
			SE1->(DbSkip ())
		EndDo
	EndIf
	

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Pesquisa itens de nota                                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea("SD2")
	dbSetOrder(3)
	#IFDEF TOP
		lQuery  := .T.
		cAliasSD2 := GetNextAlias()
		BeginSql Alias cAliasSD2
				SELECT D2_FILIAL,D2_SERIE,D2_DOC,D2_CLIENTE,D2_LOJA,D2_COD,D2_TES,D2_NFORI,D2_SERIORI,D2_ITEMORI,D2_TIPO,D2_ITEM,D2_CF,
				D2_QUANT,D2_TOTAL,D2_DESCON,D2_VALFRE,D2_SEGURO,D2_PEDIDO,D2_ITEMPV,D2_DESPESA,D2_VALBRUT,D2_VALISS,D2_PRUNIT,
				D2_CLASFIS,D2_PRCVEN,D2_IDENTB6,D2_CODISS,D2_DESCZFR,D2_PREEMB,D2_DESCZFC,D2_DESCZFP,D2_LOTECTL,D2_NUMLOTE,D2_ICMSRET,D2_VALPS3,
				D2_ORIGLAN,D2_VALCF3,D2_VALIPI,D2_VALACRS,D2_PICM,D2_PDV,D2_UM
				FROM %Table:SD2% SD2
				WHERE
				SD2.D2_FILIAL  = %xFilial:SD2% AND
				SD2.D2_SERIE   = %Exp:SF2->F2_SERIE% AND
				SD2.D2_DOC     = %Exp:SF2->F2_DOC% AND
				SD2.D2_CLIENTE = %Exp:SF2->F2_CLIENTE% AND
				SD2.D2_LOJA    = %Exp:SF2->F2_LOJA% AND
				SD2.%NotDel%
				ORDER BY D2_FILIAL,D2_DOC,D2_SERIE,D2_CLIENTE,D2_LOJA,D2_ITEM,D2_COD
		EndSql

	#ELSE
		MsSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA)
	#ENDIF
	
	While !Eof() .And. xFilial("SD2") == (cAliasSD2)->D2_FILIAL .And.;
		SF2->F2_SERIE == (cAliasSD2)->D2_SERIE .And.;
		SF2->F2_DOC == (cAliasSD2)->D2_DOC

		If !Empty(cContrato)
			SC6->( dbSetOrder(1) )
			If SC6->(MsSeek(xFilial("SC6")+(cAliasSD2)->D2_PEDIDO+(cAliasSD2)->D2_ITEMPV+(cAliasSD2)->D2_COD ))
				cContrSC6	:= SC6->C6_CONTRT
				cItemSC6	:= SC6->C6_ITEM
				cPedCli		:= SC6->C6_PEDCLI
			EndIf
		EndIf

		SB1->(dbSetOrder(1))
		SB1->(MsSeek(xFilial("SB1")+(cAliasSD2)->D2_COD ))

		aadd(aProd,{ cItemSC6,;
					(cAliasSD2)->D2_COD,;
					SB1->B1_DESC,;
					(cAliasSD2)->D2_UM,;
					(cAliasSD2)->D2_QUANT,;
					(cAliasSD2)->D2_PRCVEN,;
					(cAliasSD2)->D2_TOTAL,;
					(cAliasSD2)->D2_LOTECTL,;
					(cAliasSD2)->D2_NUMLOTE,;
					AllTrim(cContrSC6),;
					cPedCli,;
					SB1->B1_CODBAR})

		(cAliasSD2)->( dbSkip() )
	EndDo
		
EndIf

If !Empty(aNota) .And. !Empty(cXml)
	cString := '<INVOIC_NFE_COMPL version="2.00" erp="PROTHEUS" erpversion="11">'
	cString += EspXml(cXml)
	cString += '<COMPLEMENT_NFE>'
	cString += EspHeader(aNota)
	cString += '<ns1:PAYMENT xmlns:ns1="TotvsColabAviso">'
	If Len(aPgto) > 1
		nPercPgto := (100/Len(aPgto))
	Else
		nPercPgto := 100
	EndIf
	For nX := 1 To Len(aPgto)
		cString += EspCondPg(aPgto[nX],Iif(Len(aPgto) > 1,'21','1'),.T.,nPercPgto)
	Next
	If Len(aPgto) == 0
		cString += EspCondPg(aPgto,'1',.F.,nPercPgto)
	EndIf
	cString += '</ns1:PAYMENT>'
	cString += '<ns1:ITENS xmlns:ns1="TotvsColabAviso">'
	For nX := 1 To Len(aProd)
		cString += EspItem(aProd[nX],AllTrim(Str(nX)))
	Next nX
	cString += '</ns1:ITENS>'
// 	cString += EspEtiq()
//	cString += EspKanban()
//	cString += EspInvRef()
	cString += EspSummary()
//	cString += EspAddFiel()
	cString += '</COMPLEMENT_NFE>'
	cString += '</INVOIC_NFE_COMPL>'
EndIf

Return EncodeUTF8(cString)

//-------------------------------------------------------------------
/*/{Protheus.doc} EspXml
Montagem da Tag NFE_SEFAZ com o conteudo do XML de Transmissao.

@sample 	EspXml()

@author		Leonardo Kichitaro
@since		18/04/2015
@version	P11.8
/*/
//-------------------------------------------------------------------
Static Function EspXml(cXml)

Local cString := ""

cString += '<NFE_SEFAZ>'+cXml+'</NFE_SEFAZ>'

Return cString

//-------------------------------------------------------------------
/*/{Protheus.doc} EspHeader
Montagem da Tag Header com o conteudo do XML de Transmissao.

@sample 	EspHeader()

@author		Leonardo Kichitaro
@since		18/04/2015
@version	P11.8
/*/
//-------------------------------------------------------------------
Static Function EspHeader(aNota)
Local cString := ""

cString += '<ns1:HEADER xmlns:ns1="TotvsColabAviso">'
cString += '<ns1:numbernf>'+aNota[2]+'</ns1:numbernf>'
cString += '<ns1:seriesnf>'+aNota[1]+'</ns1:seriesnf>'
cString += '<ns1:datetimeoutput></ns1:datetimeoutput>'
cString += '<ns1:datetimedelivery></ns1:datetimedelivery>'
cString += '<ns1:pricelist></ns1:pricelist>'
cString += '<ns1:cfop>'+aNota[3]+'</ns1:cfop>'
cString += '<ns1:numpurchaseorder>'+aNota[4]+'</ns1:numpurchaseorder>'
cString += '<ns1:numcontract>'+aNota[5]+'</ns1:numcontract>'
cString += '<ns1:eanbuyer></ns1:eanbuyer>'
cString += '<ns1:eancollection></ns1:eancollection>'
cString += '<ns1:eandelivery></ns1:eandelivery>'
cString += '<ns1:eanprovider></ns1:eanprovider>'
cString += '<ns1:eaninssuernf></ns1:eaninssuernf>'
cString += '<ns1:cnpjcollection>'+aNota[6]+'</ns1:cnpjcollection>'
cString += '<ns1:codplacedelivery></ns1:codplacedelivery>'
cString += '<ns1:codmaterialdispatcher></ns1:codmaterialdispatcher>'
cString += '<ns1:coditinerary></ns1:coditinerary>'
cString += '</ns1:HEADER>'

Return cString

//-------------------------------------------------------------------
/*/{Protheus.doc} EspCondPg
Montagem da Tag CONDITIONPAY com o conteudo do XML de Transmissao.

@sample 	EspCondPg()

@author		Leonardo Kichitaro
@since		18/04/2015
@version	P11.8
/*/
//-------------------------------------------------------------------
Static Function EspCondPg(aTitPgto,cTipoPg,lTitulo,nPercPgto)
Local cString := ""

cString += '<ns1:CONDITIONPAY>'
cString += '<ns1:conditionpay>'+cTipoPg+'</ns1:conditionpay>'
cString += '<ns1:datereference>5</ns1:datereference>'
cString += '<ns1:timereference>1</ns1:timereference>'
cString += '<ns1:typeperiod>CD</ns1:typeperiod>'
cString += '<ns1:periodnum>1</ns1:periodnum>'
If lTitulo
	cString += '<ns1:termduedate>'+SubStr(DtoS(aTitPgto[5]),1,4)+"-"+SubStr(DtoS(aTitPgto[5]),5,2)+"-"+SubStr(DtoS(aTitPgto[5]),7,2)+'</ns1:termduedate>'
	cString += '<ns1:billingdatebase>'+SubStr(DtoS(aTitPgto[4]),1,4)+"-"+SubStr(DtoS(aTitPgto[4]),5,2)+"-"+SubStr(DtoS(aTitPgto[4]),7,2)+'</ns1:billingdatebase>'
Else
	cString += '<ns1:termduedate></ns1:termduedate>'
	cString += '<ns1:billingdatebase></ns1:billingdatebase>'
EndIf
cString += '<ns1:percenttypecondpay>12E</ns1:percenttypecondpay>'
cString += '<ns1:percentcondpay>'+ConvType(nPercPgto,5,2)+'</ns1:percentcondpay>'
cString += '<ns1:typevalcondpay>262</ns1:typevalcondpay>'
If lTitulo
	cString += '<ns1:termamount>'+ConvType(aTitPgto[6],17,3)+'</ns1:termamount>'
	cString += '<ns1:duplicatenum>'+AllTrim(aTitPgto[2])+'</ns1:duplicatenum>'
	cString += '<ns1:codconditionpay>'+AllTrim(aTitPgto[7])+'</ns1:codconditionpay>'
Else
	cString += '<ns1:termamount></ns1:termamount>'
	cString += '<ns1:duplicatenum></ns1:duplicatenum>'
	cString += '<ns1:codconditionpay></ns1:codconditionpay>'
EndIf
cString += '</ns1:CONDITIONPAY>'

Return cString

//-------------------------------------------------------------------
/*/{Protheus.doc} EspItem
Montagem da Tag ITEM com o conteudo do XML de Transmissao.

@sample 	EspItem()

@author		Leonardo Kichitaro
@since		18/04/2015
@version	P11.8
/*/
//-------------------------------------------------------------------
Static Function EspItem(aProdIt,cNumIt)
Local cString := ""

cString += '<ns1:ITEM>'
cString += '<ns1:orderline>'+cNumIt+'</ns1:orderline>'
cString += '<ns1:numitemrequest>'+aProdIt[1]+'</ns1:numitemrequest>'
cString += '<ns1:typecodprod>BP</ns1:typecodprod>'
cString += '<ns1:itemcode>'+aProdIt[12]+'</ns1:itemcode>'
cString += '<ns1:prodcodsuplli></ns1:prodcodsuplli>'
cString += '<ns1:itemreferencecode></ns1:itemreferencecode>'
cString += '<ns1:itemunitofmeasure>'+aProdIt[4]+'</ns1:itemunitofmeasure>'
cString += '<ns1:descunitofmeasure>'+aProdIt[4]+'</ns1:descunitofmeasure>'
cString += '<ns1:orderedquantity>'+ConvType(aProdIt[5],17,3)+'</ns1:orderedquantity>'
cString += '<ns1:ponumber>'+aProdIt[11]+'</ns1:ponumber>'
cString += '<ns1:providernumber></ns1:providernumber>'
cString += '<ns1:numorderbuy></ns1:numorderbuy>'
cString += '<ns1:grossweight></ns1:grossweight>'
cString += '<ns1:grossvolume></ns1:grossvolume>'
cString += '<ns1:cubagem></ns1:cubagem>'
cString += '<ns1:valtotserviceitem></ns1:valtotserviceitem>'
cString += '</ns1:ITEM>'

Return cString

//-------------------------------------------------------------------
/*/{Protheus.doc} EspEtiq
Montagem da Tag ETIQUETTA com o conteudo do XML de Transmissao.

@sample 	EspEtiq()

@author		Leonardo Kichitaro
@since		18/04/2015
@version	P11.8
/*/
//-------------------------------------------------------------------
Static Function EspEtiq()
Local cString := ""

cString += '<ns1:ETIQUETTA xmlns:ns1="TotvsColabAviso">'
cString += '<ns1:conditionunit></ns1:conditionunit>'
cString += '<ns1:qtdpartsconditionunit></ns1:qtdpartsconditionunit>'
cString += '<ns1:numinvoicepackage></ns1:numinvoicepackage>'
cString += '<ns1:serieinvoicepackage></ns1:serieinvoicepackage>'
cString += '<ns1:qtdpackage></ns1:qtdpackage>'
cString += '<ns1:qtdpartsunitofmeasure></ns1:qtdpartsunitofmeasure>'
cString += '<ns1:numetiquettaum></ns1:numetiquettaum>'
cString += '<ns1:numetiquettauc></ns1:numetiquettauc>'
cString += '<ns1:lotnum></ns1:lotnum>'
cString += '<ns1:numbercall></ns1:numbercall>'
cString += '</ns1:ETIQUETTA>'

Return cString

//-------------------------------------------------------------------
/*/{Protheus.doc} EspKanban
Montagem da Tag CALL_KANBAN com o conteudo do XML de Transmissao.

@sample 	EspKanban()

@author		Leonardo Kichitaro
@since		18/04/2015
@version	P11.8
/*/
//-------------------------------------------------------------------
Static Function EspKanban()
Local cString := ""

cString += '<ns1:CALL_KANBAN xmlns:ns1="TotvsColabAviso">'
cString += '<ns1:numbercall></ns1:numbercall>'
cString += '<ns1:datecall></ns1:datecall>'
cString += '<ns1:qtdpackagecall></ns1:qtdpackagecall>'
cString += '<ns1:qtditenscall></ns1:qtditenscall>'
cString += '</ns1:CALL_KANBAN>'

Return cString

//-------------------------------------------------------------------
/*/{Protheus.doc} EspInvRef
Montagem da Tag INVOICEREFERENCED com o conteudo do XML de Transmissao.

@sample 	EspInvRef()

@author		Leonardo Kichitaro
@since		18/04/2015
@version	P11.8
/*/
//-------------------------------------------------------------------
Static Function EspInvRef()
Local cString := ""

cString += '<ns1:INVOICEREFERENCED xmlns:ns1="TotvsColabAviso">'
cString += '<ns1:numinvoicereferenced></ns1:numinvoicereferenced>'
cString += '<ns1:serieinvoicereferenced></ns1:serieinvoicereferenced>'
cString += '<ns1:inssuanceinvoicereferenced></ns1:inssuanceinvoicereferenced>'
cString += '<ns1:iteminvoicereferenced></ns1:iteminvoicereferenced>'
cString += '</ns1:INVOICEREFERENCED>'

Return cString

//-------------------------------------------------------------------
/*/{Protheus.doc} EspSummary
Montagem da Tag SUMMARY com o conteudo do XML de Transmissao.

@sample 	EspSummary()

@author		Leonardo Kichitaro
@since		18/04/2015
@version	P11.8
/*/
//-------------------------------------------------------------------
Static Function EspSummary()
Local cString := ""

cString += '<ns1:SUMMARY xmlns:ns1="TotvsColabAviso">'
cString += '<ns1:qtdtotpackage></ns1:qtdtotpackage>'
cString += '<ns1:qtdtotpallets></ns1:qtdtotpallets>'
cString += '<ns1:totcubage></ns1:totcubage>'
cString += '<ns1:numunitbilled></ns1:numunitbilled>'
cString += '<ns1:valtotreduction></ns1:valtotreduction>'
cString += '<ns1:valbaseicmsred></ns1:valbaseicmsred>'
cString += '<ns1:valtoticmsred></ns1:valtoticmsred>'
cString += '<ns1:valbaseipi></ns1:valbaseipi>'
cString += '<ns1:valtotipi></ns1:valtotipi>'
cString += '<ns1:valtotservice></ns1:valtotservice>'
cString += '</ns1:SUMMARY>'

Return cString

//-------------------------------------------------------------------
/*/{Protheus.doc} EspAddFiel
Montagem da Tag ADDFIELD com o conteudo do XML de Transmissao.

@sample 	EspAddFiel()

@author		Leonardo Kichitaro
@since		18/04/2015
@version	P11.8
/*/
//-------------------------------------------------------------------
Static Function EspAddFiel()
Local cString := ""

cString += '<ns1:ADDFIELD xmlns:ns1="TotvsColabAviso">'
cString += '<ns1:field></ns1:field>'
cString += '<ns1:value></ns1:value>'
cString += '</ns1:ADDFIELD>'

Return cString

Static Function ConvType(xValor,nTam,nDec)

Local cNovo := ""
DEFAULT nDec := 0
Do Case
	Case ValType(xValor)=="N"
		If xValor <> 0
			cNovo := AllTrim(Str(xValor,nTam,nDec))	
		Else
			cNovo := "0"
		EndIf
	Case ValType(xValor)=="D"
		cNovo := FsDateConv(xValor,"YYYYMMDD")
		cNovo := SubStr(cNovo,1,4)+"-"+SubStr(cNovo,5,2)+"-"+SubStr(cNovo,7)
	Case ValType(xValor)=="C"
		If nTam==Nil
			xValor := AllTrim(xValor)
		EndIf
		DEFAULT nTam := 60
		cNovo := AllTrim(EnCodeUtf8(NoAcento(SubStr(xValor,1,nTam))))
EndCase
Return(cNovo)