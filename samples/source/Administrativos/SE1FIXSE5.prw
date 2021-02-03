#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWIZARD.CH"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³FIXSE5Fil  ºAutor  ³TOTVS SA           º Data ³  20/05/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Funcao principal para alteração de campos na base de dados º±±
±±º          ³                                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function FIXSE5Fil()
Private oWizard
Private lOk		:= .T.
AjustaSX1()
oWizard := APWizard():New( "Assistente para Ajuste de base." ,"Atenção!" ,;
"",;
"Este assistente tem como finalidade acertar o campo FILORIG da tabela SE5 com relação aos registros da tabela SE1 que estão diferentes.";
+CHR(10)+CHR(13)+"- Somente rodar este ajuste em modo exclusivo!";
+CHR(10)+CHR(13)+"- Realizar backup do banco de dados antes da atualização.";
+CHR(10)+CHR(13)+"- Rodar a atualização primeiramente em base de homologação.",;
{|| .T.}, {|| Processa({|lEnd| FinExecFix() }),.T.},,,,,) 
			

ACTIVATE WIZARD oWizard CENTERED  WHEN {||.T.}

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³FinExecFixºAutor  ³TOTVS SA            º Data ³  20/05/14   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Funcao que executa o acerto do campo E5_FILORIG com relaçãoº±±
±±º          ³ aos registros contidos na tabela SE1.                      º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ AP                                                        º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function FinExecFix()
Local aArea := GetArea()
Local aRecLogOK	 := {}
Local aRecLogNOK	 := {}   
Local nX			 := 0 
Local cPath		 := "" 
Local cQuery	:= ""       
Local cFiltro := ""
Local cFilSE1 := ""
Local lNaoAchou := .T.
Local nCount := 0

If MsgYesNo("A base de dados será alterada após esta confirmação! Tem certeza que deseja atualizá-la?")
	If !Pergunte("FIXSE5",.T.)
		Return .F.
	EndIf	
	
	DbSelectArea("SE5")
	/*Filtro da SE5*/
	cFiltro:="E5_FILIAL>='"+mv_par01+"' "	
	cFiltro += ".AND. E5_FILIAL<='"+mv_par02+"' "
	cFiltro += ".AND. E5_DATA 	>= CTOD('"+dToc(mv_par03)+"') "
	cFiltro += ".AND. E5_DATA 	<= CTOD('"+dToc(mv_par04)+"') "
	cFiltro += ".AND. E5_CLIFOR 	>= '"+mv_par05+"' "
	cFiltro += ".AND. E5_CLIFOR 	<= '"+mv_par06+"' "
	cFiltro += ".AND. (E5_RECPAG  == 'R' "
	cFiltro += ".OR. (E5_RECPAG  == 'P' .AND.  E5_MOTBX  == 'DAC'))"
	//cFiltro += ".AND. E5_MOTBX  == 'CMP' "
	/*Fim filtro SE5*/
 	Dbsetfilter({|| &cFiltro},cFiltro)	
	SE5->(DbGoTop())
	
	While SE5->(!Eof())
		nCount++
		ProcRegua(nCount)
		//Localiza o titulo com a mesma filial
		cQuery := "SELECT E1_FILIAL , E1_FILORIG FROM " 
		cQuery += RetSqlName("SE1")
		cQuery += " WHERE "
		cQuery += " E1_FILIAL = '"  + SE5->E5_FILIAL+ "'"
		cQuery += " AND E1_CLIENTE = '" + SE5->E5_CLIFOR+ "'"
		cQuery += " AND E1_LOJA = '"    +SE5->E5_LOJA + "'"
		cQuery += " AND E1_PREFIXO = '" + SE5->E5_PREFIXO+ "'"
		cQuery += " AND E1_NUM = '"     + SE5->E5_NUMERO + "'"
		cQuery += " AND E1_PARCELA = '" +SE5->E5_PARCELA + "'"
		cQuery += " AND E1_TIPO = '"    +SE5->E5_TIPO + "'"
		cQuery += " AND D_E_L_E_T_ = ' '"
	
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRB",.T.,.T.)
		If TRB->(!Eof())
				If SE5->E5_FILORIG <> TRB->E1_FILIAL
					Reclock("SE5",.F.)
					SE5->E5_FILORIG := TRB->E1_FILIAL
					SE5->(MsUnlock())		
								
					aAdd(aRecLogOK,{"Recno:" + strzero(SE5->(Recno()),6) + " Titulo: " + SE5->(E5_FILIAL + E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA)+" - "+;
				  			   "Atualizado FilOrig: " + 	SE5->E5_FILORIG })
				EndIf
		ElseIf TRB->(Eof())
			//não encontrou o titulo, busca sem filial
			TRB->(DBCloseArea())
			cQuery := "SELECT E1_FILIAL , E1_FILORIG FROM " 
			cQuery += RetSqlName("SE1")
			cQuery += " WHERE "
			cQuery += " E1_CLIENTE = '" + SE5->E5_CLIFOR+ "'"
			cQuery += " AND E1_LOJA = '"    +SE5->E5_LOJA + "'"
			cQuery += " AND E1_PREFIXO = '" + SE5->E5_PREFIXO+ "'"
			cQuery += " AND E1_NUM = '"     + SE5->E5_NUMERO + "'"
			cQuery += " AND E1_PARCELA = '" +SE5->E5_PARCELA + "'"
			cQuery += " AND E1_TIPO = '"    +SE5->E5_TIPO + "'"
			cQuery += " AND D_E_L_E_T_ = ' '"
		
			dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),"TRB",.T.,.T.)
					
			If TRB->(!Eof())
				If SE5->E5_FILORIG <> TRB->E1_FILIAL
					//guarda a filial para gravar depois
					cFilSE1 :=  TRB->E1_FILIAL
					
					TRB->(DBSkip()) // verifica se encontrou mais de um titulo
					If  TRB->(Eof())
						//Se não encontrou mais de um titulo, atualiza
						Reclock("SE5",.F.)
						SE5->E5_FILORIG := cFilSE1
						SE5->(MsUnlock())		
						aAdd(aRecLogOK,{"Recno:" + strzero(SE5->(Recno()),6) + " Titulo: " + SE5->(E5_FILIAL + E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA)+" - "+;
				  			   "Atualizado FilOrig: " + 	SE5->E5_FILORIG })
					Else
						//encontrou mais de um titulo em filiais diferentes, gera log
						aAdd(aRecLogNOK,{"Recno:" + strzero(SE5->(Recno()),6) + " Titulo: " + SE5->(E5_FILIAL + E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA)+" - "+;
			  			   "Encontrou mais de um titulo."})
					
					EndIf								
				EndIf
			Else								
				aAdd(aRecLogNOK,{"Recno:" + strzero(SE5->(Recno()),6) + " Titulo: " + SE5->(E5_FILIAL + E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA)+" - "+;
			  			   "Não encontrou o título correspondente."})
			EndIf  			   
		EndIf  
		   
		TRB->(DBCloseArea())
		SE5->(DbSkip())
	
	EndDo  
EndIf

// ********* GERAÇÃO DO LOG ********* //
If Len(aRecLogOK) > 0
	lNaoAchou := .F.
	AutoGrLog("LOG de alterações na tabela SE5 - " +DtoC(MsDate())+ ' ' + Time() )
	AutoGrLog("Cada linha apresentada abaixo é referente")
	AutoGrLog("a um registro da tabela SE5 que foi atualizado.")
	AutoGrLog("Onde Titulo = E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA")
	For nX := 1 To Len(aRecLogOK)
		AutoGrLog(aRecLogOK[nX][1])
	Next nX
EndIf
If Len(aRecLogNOK) > 0
	lNaoAchou := .F.
	AutoGrLog("===============================================================")
	AutoGrLog("******************* ERROS ENCONTRADOS *************************")
	For nX := 1 To Len(aRecLogNOK)
		AutoGrLog(aRecLogNOK[nX][1])
	Next nX
EndIf

		
If lNaoAchou
	AutoGrLog("LOG de alterações na tabela SE5 - " +DtoC(MsDate())+ ' ' + Time() )
	AutoGrLog("Não foram encontrados registros para atualizar.")
EndIf

cFileLog := NomeAutoLog()

If cFileLog <> ""
	MostraErro(cPath,cFileLog)
Endif

RestArea(aArea)
Return 


//Criação de pergunte para o filtro da SE5
Static Function AjustaSX1()

Local aArea		:= GetArea()
Local cPerg := "FIXSE5"
Local ntamFil := Len(xFilial("SE1"))
Local nTamCli := Len(SE1->E1_CLIENTE)
DbselectArea("SX1")
DBSetOrder(1)

//PutSX1( < cGrupo>, < cOrdem>, < cPergunt>, < cPergSpa>, < cPergEng>, < cVar>, < cTipo>, < nTamanho>, [ nDecimal], [ nPreSel], < cGSC>, [ cValid], [ cF3], [ cGrpSXG], [ cPyme], < cVar01>, [ cDef01], [ cDefSpa1], [ cDefEng1], [ cCnt01], [ cDef02], [ cDefSpa2], [ cDefEng2], [ cDef03], [ cDefSpa3], [ cDefEng3], [ cDef04], [ cDefSpa4], [ cDefEng4], [ cDef05], [ cDefSpa5], [ cDefEng5], [ aHelpPor], [ aHelpEng], [ aHelpSpa], [ cHelp] )

//Inclusão de pergunta considera filial original
If SX1->(!DbSeek(padr(cPerg,10) ))
	PutSx1( cPerg, "01","Filial De?","Filial De?","Filial De?","mv_cha","C",ntamFil,0,0,"G","","SM0","033","",;
		"mv_par01","","","",Space(ntamFil),"","","","","","","","","","","","",,,,"")
		
	PutSx1( cPerg, "02","Filial Até?","Filial Até?","Filial Até?","mv_chb","C",ntamFil,0,0,"G","","SM0","033","",;
		"mv_par02","","","",Replicate("Z",nTamCli),"","","","","","","","","","","","",,,,"")
		
	PutSx1( cPerg, "03","Data De?","Data De?","Data De?","mv_chc","D",8,0,0,"G","","","","",;
		"mv_par03","","","","","","","","","","","","","","","","",,,,"")

	PutSx1( cPerg, "04","Data Ate?","Data Ate?","Data Ate?","mv_chd","D",8,0,0,"G","","","","",;
		"mv_par04","","","","","","","","","","","","","","","","",,,,"")
		
	PutSx1( cPerg, "05","Cliente De?","Cliente De?","Cliente De?","mv_che","C",nTamCli,0,0,"G","","SA1CLI","001","",;
		"mv_par05","","","",Space(nTamCli),"","","","","","","","","","","","",,,,"")

	PutSx1( cPerg, "06","Cliente Ate?","Cliente Ate?","Cliente Ate?","mv_chf","C",nTamCli,0,0,"G","","SA1CLI","001","",;
		"mv_par06","","","",Replicate("Z",nTamCli),"","","","","","","","","","","","",,,,"")
		
EndIf
RestArea(aArea)
Return	
		