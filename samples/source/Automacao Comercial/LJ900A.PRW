#Include 'Protheus.ch'
#Include 'TopConn.ch'


		
//-------------------------------------------------------------------
/*/{Protheus.doc} LJ900AM
Interface da Rotina de Atualização dos Produtos EC CiaShop
@author  Varejo
@version 	P11.8
@since   	16/07/2015
@obs     
@sample 	U_LJ900AM()
/*/
//-------------------------------------------------------------------		
		
User Function LJ900AM()
Local oDlg 	:= NIL //objeto Dialog
Local oPanel1 := NIL  //panel
Local oSay1 	:= NIL //Say

DEFINE MSDIALOG oDlg TITLE 'Atualização Produtos  EC CiaShop' From 000,0 TO 100,300 PIXEL
	oDlg:lMaximized := .T. 
	@ 000, 000 MSPANEL oPanel1 SIZE 10, 50 OF oDlg 
	@ 12, 05 SAY oSay1 VAR 'O botão Processa executa a seleção e atualização' OF oPanel1 PIXEL                                                                           
	
	oPanel1:align:= CONTROL_ALIGN_TOP   
	@ 25, 40 BUTTON 'Processar' PIXEL SIZE 40,12 OF oPanel1 ACTION LJ900APR()  
	@ 25, 100 BUTTON 'Fechar' PIXEL SIZE 40,12 OF oPanel1 ACTION oDlg:End()

ACTIVATE MSDIALOG oDlg CENTERED

Return                                                                        


//-------------------------------------------------------------------
/*/{Protheus.doc} LJ900APR
Processamento da rotina de Atualização dos Produtos EC CiaShop
@author  Varejo
@version 	P11.8
@since   	16/07/2015
@obs     
@sample 	LJ900APR
/*/
//-------------------------------------------------------------------		
Static Function LJ900APR()

Local cPerg := "UL900" //Nome da Pergunta
Local lValidVar := MsgYesNo("Valida estrutura de variantes")
Local dDataIni := Date()
Local cHoraIni := Time()

CriaSX1(cPerg)
Pergunte(cPerg, .T.)


Lj900XLg("Iniciando execução da Rotina LJ900APR" + DtoC(dDataIni) + " Hora " + cHoraIni)
//Processa( {|| U_LJ900A(lValidVar) }, 'Aguarde...', 'Atualizando Produto-Pai',.F.)
U_LJ900A(lValidVar)
//Processa( {|| U_LJ900AD(.F.) }, 'Aguarde...', 'Atualizando Dados e-commerce',.F.)
U_LJ900AD(.F.)

Lj900XLg("Finalizando execução da Rotina LJ900APR Inicio " + Dtos(dDataIni) + " Hora " + cHoraIni + ;
		" Final " `+ DtoC(Date()) + " Hora " + Time())

Lj900XLg("Registros Atualizados")

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} U_LJ900A
Realiza a seleção dos Produtos para atualizar o Produto-pai da Grade
@author  Varejo
@version 	P11.8
@since   	16/07/2015
@obs     
@sample 	U_LJ900A()
/*/
//-------------------------------------------------------------------
User Function LJ900A(lValidVar)

Local aArea		:= GetArea() //WorkArea Ativa
Local cTrab		:= "" //Alias Temporario
Local cQuery		:= ""	//Query
Local aMasc 		:=  &("{"+AllTrim(SuperGetMV("MV_MASCGRD",,""))+"}") //Mascara
Local nTamGrd 	:= 0 //Tamanho do campo grade
Local aGrades 	:= {} //Array de Grades //Raiz, Pai
Local nPosGrd 	:= 0 //Posicao da Grade
Local cGrdAnt 	:= "" //Codigo Raiz Anterior
Local cProdPai	:= "" //Produto-Pai
Local nTotRec 	:= 0 //Total de Registros
Local nRecAtu 	:= 0 //Registros Processados
Local cMsg 		:= "" //Mensagem

Default lValidVar := .T. //valida estrutura de variante

If Len(aMasc) < 3
	Erro("Problemas no parâmetro MV_MASCGRD")
	Return
Else

	
	nTamGrd := aMasc[1]+aMasc[2]+aMasc[3] 
	
	If Len(aMasc) = 4
		nTamGrd +=aMasc[4] //GCV
	EndIf

	cTrab := GetNextAlias()
	If Select(cTrab) > 0
		(cTrab)->(DbCloseArea())
	EndIf
	


	LjMsgrun("Selecionado registros de grade de Produtos", "Aguarde", { || Lj900AB4(cTrab, @nTotRec, aMasc) })


	cGrdAnt := ""
	//(cTrab)->(DbEval({ || nTotRec := nTotRec + 1} ))
	
	(cTrab)->(DbGoTop())
	
	//ProcRegua(nTotRec)
	nPosGrd := 0
	
	While (cTrab)->(!Eof())
		nRecAtu++
	
		cMsg := "> Localizando Pai do Produto "+ AllTrim((cTrab)->B1_COD) + " Registro: " + Str(nRecAtu)+" de "+Str(nTotRec)
		Lj900XLg(cMsg, (cTrab)->B1_COD)
		
		LjMsgrun(cMsg, "Atualizando Produto-Pai", { ||  LJ900ADr(cTrab, aMasc, @cGrdAnt, @aGrades, lValidVar, @nPosGrd)}) 
			
		//IncProc(cMsg)
		//Produtos cadastrados no GCV podem haver ter SB4, porém não tem linhas/colunas
			//Linha															//Coluna
		(cTrab)->(dbSkip())
	End                 
	

	
	(cTrab)->(dbCloseArea())

EndIf

RestArea(aArea)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} LJ900APC
Realiza a busca de um produto-pai cadastrado
@param   	cB4_COD - Codigo da Grade/Raiz
@param   	cB1_COD - Codigo do Produto
@param   	nRaiz - Tamanho da Raiz
@author  Varejo
@version 	P11.8
@Return 	cProdPai - Produto-Pai
@since   	16/07/2015
@obs     
@sample 	LJ900APC( cB4_COD, cB1_COD, nRaiz)
/*/
//-------------------------------------------------------------------
Static Function LJ900APC( cB4_COD, cB1_COD, nRaiz)
Local aArea 		:= GetArea() //WorkAreaAtiva
Local cProdPai 	:= "" //Produto-Pai Localizado
Local cQuery 		:= "" //Query
Local cTrab 		:= "" //Alias temporário


cTrab := GetNextAlias()
If Select(cTrab) > 0
	(cTrab)->(DbCloseArea())
EndIf

cQuery := "SELECT B1_COD FROM " +;
			RetSQLName("SB1") +" SB1, " + ;
			RetSQLName("SB4") + " SB4 WHERE "
cQuery += "SUBSTRING(B1_COD,1," +Str(nRaiz) +") =  " + "SUBSTRING(B4_COD,1," +Str(nRaiz) +")  "  +;
		  " AND B4_COD = '" + cB4_COD + "'"+;
		  " AND B1_GRADE = 'S'  "+;
		   " AND B1_PRODPAI = B1_COD "
cQuery += " AND SB4.D_E_L_E_T_ = '' "+;
			" AND B4_FILIAL = '" +xFilial("SB4") +"' "
cQuery += " AND SB1.D_E_L_E_T_ = '' "+;
			" AND B1_FILIAL = '" +xFilial("SB1") +"' " + ;
			"AND B1_PRODPAI <> ''  "
			
cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTrab,.T.,.T.)

If !(cTrab)->(Eof())
	cProdPai := (cTrab)->B1_COD
	
	Lj900XLg("Localizado B1_PRODPAI da Grade " + cB4_COD + " B1_PRODPAI " + (cTrab)->B1_COD)
EndIf

(cTrab)->(DbCloseArea())
		
RestArea(aArea)
Return cProdPai


//-------------------------------------------------------------------
/*/{Protheus.doc} LJ900APC
Localiza e Valida a Estrutura de um Produto-pai
@param   	cB4_COD - Codigo da Grade/Raiz
@param   	cB1_COD - Codigo do Produto
@param   	nRaiz - Tamanho da Raiz
@param   	nLinha - Tamanho da Linha
@param   	nColuna - Tamanho da Coluna
@author  Varejo
@version 	P11.8
@Return 	cProdPai - Produto-Pai
@since   	16/07/2015
@obs     
@sample 	LJ900APV( cB4_COD, cB1_COD, nRaiz, nLinha, nColuna)
/*/
//-------------------------------------------------------------------
Static Function LJ900APV( cB4_COD, cB1_COD, nRaiz, nLinha, nColuna, lValidVar)
Local lEstrVld := .F. //Estrutura Válida
Local cProdPai := "" //Produto-Pai Retornado
Local cPaiPesq := "" //Pai Localizado
Local aTrab 	:= {}	//Array de Produtos Localizados	
Local cTrab 	:= "" //Alias Temporário


Default lValidVar := .T. //Valida pai?


If lValidVar

cTrab := LJ900APP(cB4_COD, nRaiz)
//consulta produtos

(cTrab)->( DbEval( { || aAdd(aTrab, FIELD->B1_COD)  } ))

ASORT(aTrab,,, { |x, y| x < y } ) 

(cTrab)->(DbCloseArea())

//pesquisa sb5, acv
//valida o pai

cPaiPesq := LJ900APS(cB4_COD,nRaiz )

If Empty(cPaiPesq)
	cPaiPesq := cB1_COD
EndIf

//pai valido? sim
lEstrVld := LJ900AVE(cB4_COD, @cPaiPesq, aTrab, nRaiz, nLinha, nColuna)

//pai valido? sim
If !lEstrVld
	cProdPai := ".F."
Else
	cProdPai := cPaiPesq
EndIf

Else
	//Não precisa validar o pai, o primeiro que localizar é valido
	
	cProdPai := cB1_COD
EndIf

Return cProdPai 

//-------------------------------------------------------------------
/*/{Protheus.doc} Lj900APP
Retorna os Produtos pertencentes a Grade
@param   	cB4_COD - Codigo da Grade/Raiz
@param   	nRaiz - Tamanho da Raiz
@author  Varejo
@version 	P11.8
@Return 	cTrab - WorkArea com os produtos
@since   	16/07/2015
@obs     
@sample 	Lj900APP( cB4_COD, nRaiz)
/*/
//-------------------------------------------------------------------
Static Function Lj900APP( cB4_COD, nRaiz)
Local cTrab 	:= "" //WorkArea com Produtos
Local cQuery 	:= "" //Query de consulta

cTrab := GetNextAlias()
If Select(cTrab) > 0
	(cTrab)->(DbCloseArea())
EndIf

cQuery := "SELECT B1_COD FROM " +;
			RetSQLName("SB1") +" SB1, " + ;
			RetSQLName("SB4") + " SB4 WHERE "
cQuery += "SUBSTRING(B1_COD,1," +Str(nRaiz) +") =  " + "SUBSTRING(B4_COD,1," +Str(nRaiz) +")  "  +;
		  " AND B4_COD = '" + cB4_COD + "'"+;
		  " AND B1_GRADE = 'S'  "
cQuery += " AND SB4.D_E_L_E_T_ = '' "+;
			" AND B4_FILIAL = '" +xFilial("SB4") +"' " 
cQuery += " AND SB1.D_E_L_E_T_ = '' "+;
			" AND B1_FILIAL = '" +xFilial("SB1") +"' " +;
			 " AND B4_COD = '" + cB4_COD + "'"
			 
cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTrab,.T.,.T.)

Return cTrab


//-------------------------------------------------------------------
/*/{Protheus.doc} Lj900APS
Realiza a busca de um produto elegível como pai
@param   	cB4_COD - Codigo da Grade/Raiz
@param   	nRaiz - Tamanho da Raiz
@author  Varejo
@version 	P11.8
@Return 	cProd - Produto-Pai
@since   	16/07/2015
@obs     
@sample 	Lj900APP( cB4_COD, nRaiz)
/*/
//-------------------------------------------------------------------			 
Static Function Lj900APS( cB4_COD, nRaiz)
Local cProd := "" 	//WorkArea com Produtos
Local cQuery := ""	//Query de consulta

cTrab := GetNextAlias()
If Select(cTrab) > 0
	(cTrab)->(DbCloseArea())
EndIf

cQuery := "SELECT B1_COD FROM " +;
			RetSQLName("SB1") +" SB1, " + ;
			RetSQLName("SB5") + " SB5 WHERE "
cQuery += "  B5_COD = B1_COD "+;
		  " AND B1_GRADE = 'S'  "
cQuery += " AND SB5.D_E_L_E_T_ = '' "+;
			" AND B5_FILIAL = '" +xFilial("SB5") +"' "
cQuery += " AND SB1.D_E_L_E_T_ = '' "+;
			" AND B1_FILIAL = '" +xFilial("SB1") +"' " +;
			" AND SUBSTRING(B1_COD,1," +Str(nRaiz) +") =  '" + cB4_COD + "'  " 
			 
cQuery := ChangeQuery(cQuery)
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTrab,.T.,.T.)

If !(cTrab)->(Eof())
	cProd := (cTrab)->B1_COD
	Lj900XLg("Localizado SB5 da Grade " + cB4_COD + " B5_COD " + (cTrab)->B1_COD)
	
Else
	//Busca o relacionamento na categoria de produtos  ACV
	(cTrab)->(DbCloseArea())
	
	cQuery := "SELECT ACV_CODPRO FROM " +;
				RetSQLName("SB1") +" SB1, " + ;
				RetSQLName("ACV") + " ACV WHERE "
	cQuery += " ACV_CODPRO = B1_COD "+;
			  " AND B1_GRADE = 'S'  "
	cQuery += " AND ACV.D_E_L_E_T_ = '' "+;
				" AND ACV_FILIAL = '" +xFilial("ACV") +"' "
	cQuery += " AND SB1.D_E_L_E_T_ = '' "+;
				" AND B1_FILIAL = '" +xFilial("SB1") +"' " +;
				" AND SUBSTRING(B1_COD,1," +Str(nRaiz) +") =  '" + cB4_COD + "'  "
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTrab,.T.,.T.)
	
	If !(cTrab)->(Eof())
		cProd := (cTrab)->ACV_CODPRO
		Lj900XLg("Localizado ACV da Grade " + cB4_COD + " ACV_CODPRO " + (cTrab)->ACV_CODPRO)
		
	EndIf
EndIf


(cTrab)->(DbCloseArea())


Return cProd

//-------------------------------------------------------------------
/*/{Protheus.doc} Lj900AVE
Realiza a validação de uma Estrutura de um produto
@param   	cB4_COD - Codigo da Grade/Raiz
@param   	cPaiPesq - Produto a ser validado
@param   	aTrab - Array de Produtos da Grade
@param   	nRaiz - Tamanho da Raiz
@param   	nLinha - Tamanho da Linha
@param   	nColuna - Tamanho da Coluna
@author  Varejo
@version 	P11.8
@Return 	lEstrVld - Estrutura Válida
@since   	16/07/2015
@obs     
@sample 	Lj900AVE(cB4_COD, cPaiPesq, aTrab,  nRaiz, nLinha, nColuna)
/*/
//-------------------------------------------------------------------	
Static Function Lj900AVE(cB4_COD, cPaiPesq, aTrab,  nRaiz, nLinha, nColuna)
Local lEstrVld := .f. //Estrutura Válida
Local cZerosLin := Replicate("0", nLinha) //Linha Zerada
Local cZerosCol := Replicate("0", nColuna) //Coluna Zerada
Local lLinZer := .F. //Linha Zerada
Local lColZer := .F. //Coluna Zerada
Local nPosNoLnZr := 0 //Posicao do array de nenhuma linha zerada
Local nPosNoClZr := 0 //Posicao do array de nenhuma linha zerada
Local nPosPrdVl := 0 //Posicao do produto valido



lLinZer := Substr(cPaiPesq, nRaiz+1, nLinha) == cZerosLin
lColZer := Substr(cPaiPesq, nRaiz+nLinha + 1, nColuna) == cZerosCol


If Empty(Substr(cPaiPesq, nRaiz+1, nLinha)) .OR. Empty(Substr(cPaiPesq, nRaiz+nLinha + 1, nColuna)) 
	//Estrutura inválida
	Lj900XLg("Localizado produto-pai com linha/coluna em branco [" + cPaiPesq + "]" )
	Return lEstrVld 
EndIf

If !lLinZer .AND. !lColZer
		lEstrVld := .T.
Else
	//ou Linha ou coluna Zerada
	//Verifica se há validações de linha não zerada
	If lLinZer
		nPosNoLnZr := aScan( aTrab, { |p|  Substr(p, nRaiz+1, nLinha) <> cZerosLin })
	EndIf
	
	//Verifica se há validações de coluna não zerada
	If lColZer
		nPosNoClZr := aScan( aTrab, { |p|  Substr(p,  nRaiz+nLinha + 1, nLinha) <> cZerosCol })
	EndIf
	
	If  nPosNoLnZr == 0  .AND. nPosNoClZr == 0
		lEstrVld := .T. //Produto valido
	Else
		If !lLinZer
			 nPosNoLnZr := 1 //há variação de linha
		EndIf
		
		If !lColZer
			nPosNoClZr := 1 //há variação de coluna
			
		EndIf
		//Localiza o produto que pode ser válido
		If nPosNoLnZr > 0 .AND. nPosNoClZr > 0
			//Linha varia a coluna varia
			nPosPrdVl := aScan( aTrab, { |p|  Substr(p, nRaiz+1, nLinha) <> cZerosLin .AND.   Substr(p,  nRaiz+nLinha + 1, nLinha) <>  cZerosCol })
			
		ElseIf nPosNoLnZr > 0 .AND. nPosNoClZr == 0
			//Linha varia e coluna zerada
			nPosPrdVl := aScan( aTrab, { |p|  Substr(p, nRaiz+1, nLinha) <> cZerosLin .AND.   Substr(p,  nRaiz+nLinha + 1, nLinha) == cZerosCol })
		ElseIf nPosNoLnZr = 0 .AND. nPosNoClZr > 0
			//Linha zerada e coluna varia
			nPosPrdVl := aScan( aTrab, { |p|  Substr(p, nRaiz+1, nLinha) == cZerosLin .AND.   Substr(p,  nRaiz+nLinha + 1, nLinha) <> cZerosCol })			
		EndIf
		
		If nPosPrdVl > 0
			cPaiPesq := aTrab[nPosPrdVl]
			lEstrVld := .T.
		EndIf
	EndIf
	
	
EndIf

Return lEstrVld


//-------------------------------------------------------------------
/*/{Protheus.doc} U_Lj900AD
Realiza a validação de uma Estrutura de um produto
@param   	lPerg - Exibe Perguna (default .T.)
@author  Varejo
@version 	P11.8
@Return 	nil
@since   	16/07/2015
@obs     
@sample 	U_Lj900AD(lPerg)
/*/
//-------------------------------------------------------------------
User Function Lj900AD(lPerg)
Local cAlias 		:= GetNextAlias() //Alias da Consulta
Local aAreaSB5 	:= SB5->(GetArea()) //workArea SB5
Local aAreaSB0 	:= SB0->(GetArea()) //WorkArea SB0
Local cFilSB5 	:= xFilial("SB5") //Filial SB5
Local cFilSB0 	:= xFilial("SB0") //Filial SB0
Local cEcFlag 	:= "1" //Ativo 
Local nPeso 		:= 1 //Peso em Kg (default 1 kg)
Local cPerg 		:= "UL900" //Nome da Pergunta
Local nTotRec 	:= 0 //total de Registros selecionados
Local nRecAtu 	:= 0 //total de Registros procesados
Local cMsg 	:= "" //Mensagem
Local lLock 	:= .t.//Registro Bloqueado para atualização


default lPerg := .T.

If lPerg
	CriaSX1(cPerg)
	Pergunte(cPerg, .T.)
EndIf


If AllTrim(Str(MV_PAR01)) $ "1/2"
	cEcFlag := AllTrim(Str(MV_PAR01))
EndIf

If MV_PAR02 > 0
	nPeso := MV_PAR02
EndIf
                                                                                                                                            

If Select(cAlias) > 0
	(cAlias)->(DbCloseArea())
EndIf



LjMsgrun("Selecionado registros de produto-pai ", "Aguarde", { || LJ900AD5(cAlias) })



SB5->(DbSetOrder(1)) //B5_FILIAL+B5_COD  
SB0->(DbSetOrder(1)) //B0_FILIAL+B0_COD  

(cAlias)->(DbEval({ || nTotRec := nTotRec + 1} ))   
(cAlias)->(DbGoTop())                                                                                                                                                                                                                                                                                          

Do While !(cAlias)->(Eof())
	nRecAtu++
	cMsg := "Atualizando Dados e-commerce do Produto-Pai "+ AllTrim((cAlias)->B1_COD) + " Registro: " + Str(nRecAtu)+" de "+Str(nTotRec)
	Lj900XLg(cMsg, (cAlias)->B1_COD)
	
	//IncProc(cMsg)
	LjMsgrun(cMsg, "Atualizando Produto-Pai", { || Lj900ADP(cFilSB5, cAlias, cEcFlag, nPeso)})
 	
	(cAlias)->(DbSkip(1))
EndDo

If Select(cAlias) > 0
	(cAlias)->(DbCloseArea())
EndIf


LjMsgrun("Selecionado registros de produtos-filhos ", "Aguarde", { || LJ900AD0(cAlias) })


nRecAtu := 0
nTotRec := 0
(cAlias)->(DbEval({ || nTotRec := nTotRec + 1} ))   
(cAlias)->(DbGoTop())

Do While !(cAlias)->(Eof())
	nRecAtu++
	cMsg := "Atualizando Dados e-commerce do Produto-Filho "+ AllTrim((cAlias)->B1_COD) + " Registro: " + Str(nRecAtu)+" de "+Str(nTotRec)
	//IncProc(cMsg)
	Lj900XLg(cMsg, (cAlias)->B1_COD)
	
	Lj900AD2(cFilSB0, cAlias, cEcFlag)
			
	(cAlias)->(DbSkip(1))
EndDo


If Select(cAlias) > 0
	(cAlias)->(DbCloseArea())
EndIf

RestArea(aAreaSB0)
RestArea(aAreaSB5)


Return


//-------------------------------------------------------------------
/*/{Protheus.doc} Lj900AD5
Query para Seleção dos dados do produto sem complemento e-commerce
@param   	cAlias - Alias da Consulta
@author  Varejo
@version 	P11.8
@since   	16/07/2015
@obs     
@sample 	Lj900AD5(cAAlias)
/*/
//-------------------------------------------------------------------		
Static Function Lj900AD5(cAAlias)

//Query para Seleção dos dados do produto 
	Local cTamPai := Space(SB1->(TamSX3("B1_PRODPAI")[1]))

	BeginSQL Alias cAAlias
	
		%noparser%

		SELECT X.* FROM 
		(		
			SELECT SB1.B1_COD, SB1.B1_DESC, 
									(	SELECT COUNT(1) 
										FROM %table:SB5% SB5 
										WHERE SB5.B5_FILIAL  = %xFilial:SB5% 
												AND SB5.D_E_L_E_T_ <> '*' 
												AND SB5.B5_COD = SB1.B1_COD 
												AND SB5.B5_ECFLAG <> ' ') AS CONTA
			FROM  %table:SB1% SB1
			WHERE SB1.B1_FILIAL = %xFilial:SB1% 
			AND  ( ( ( SB1.B1_PRODPAI <> ' '  AND SB1.B1_PRODPAI <> %Exp:cTamPai%)
			AND SB1.B1_PRODPAI = SB1.B1_COD  AND SB1.B1_GRADE  = 'S' ) OR 
			  ( SB1.B1_PRODPAI = ' '  OR SB1.B1_PRODPAI = %Exp:cTamPai%)  )		
			AND SB1.B1_MSBLQL <> '1'
			AND SB1.D_E_L_E_T_ <> '*'		
		) X
		WHERE X.CONTA = 0
		

	EndSQL

	Lj900XRC( cAAlias, "LJ900AD5")
Return


//-------------------------------------------------------------------
/*/{Protheus.doc} Lj900AD5
Query para Seleção dos dados do produto sem dados e-commerce
@param   	cAlias - Alias da Consulta
@author  Varejo
@version 	P11.8
@since   	16/07/2015
@obs     
@sample 	Lj900AD0(cAAlias)
/*/
//-------------------------------------------------------------------	
Static Function Lj900AD0(cAAlias)

//Query para Seleção dos dados do produto
	Local cTamPai := Space(SB1->(TamSX3("B1_PRODPAI")[1])) 

	BeginSQL Alias cAAlias
	
		%noparser%

		SELECT X.* FROM 
		(		
			SELECT SB1.B1_COD, SB1.B1_DESC, 
									(	SELECT COUNT(1) 
										FROM %table:SB0% SB0 
										WHERE SB0.B0_FILIAL  = %xFilial:SB0% 
												AND SB0.D_E_L_E_T_ <> '*' 
												AND SB0.B0_COD = SB1.B1_COD 
												AND SB0.B0_ECFLAG <> ' ') AS CONTA
			FROM  %table:SB1% SB1
			WHERE SB1.B1_FILIAL = %xFilial:SB1% 
			AND SB1.B1_PRODPAI <> ' '  AND SB1.B1_PRODPAI <> %Exp:cTamPai%
			AND SB1.B1_GRADE  = 'S' 	
			AND SB1.B1_MSBLQL <> '1'
			AND SB1.D_E_L_E_T_ <> '*'		
		) X
		WHERE X.CONTA = 0
		

	EndSQL

	Lj900XRC( cAAlias, "LJ900AD0")
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CriaSX1
Criação da Pergunta da Rotina de Processamento
@param   	cPerg - Nome da Pergunta
@author  Varejo
@version 	P11.8
@since   	16/07/2015
@obs     
@sample 	CriaSX1(cPerg) 
/*/
//-------------------------------------------------------------------	
Static Function CriaSX1(cPerg)   
Local aHelpPor	:= {}							// Help da pergunta em portugues
Local aHelpEng	:= {}							// Help da pergunta em ingles
Local aHelpSpa	:= {}							// Help da pergunta em espanhol
Local nTamPeso 	:= SB5->(TamSX3("B5_PESO")[1]) //peso 
Local nDecPeso 	:= SB5->(TamSX3("B5_PESO")[2])	//Decimais do peso

Default cPerg := "UL900"
	                                 
aAdd(aHelpPor, "Informe o status do Produto ") //"Informe o status do Produto "
aAdd(aHelpPor, "e-commerce") //"e-commerce"
aHelpEng := aClone( aHelpPor)    
aHelpSpa := aClone( aHelpPor) 



putSx1(cPerg, '01', "Status e-comm" , "Status e-comm" , "Status e-comm" , 'mv_ch1', 'N', 1,;
 0, 1, 'C', "NaoVazio", ''   , '', '', 'mv_par01',"Ativo","Ativo","Ativo","",;
		"Inativo","Inativo","Inativo","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa) //"Status e-comm"          
		
aHelpPor := {}
aHelpEng := {}    
aHelpSpa := {}
		
aAdd(aHelpPor, "Informe o peso em kilogramas") //"Informe o peso padrão em gramas"

aHelpEng := aClone( aHelpPor)    
aHelpSpa := aClone( aHelpPor) 

putSx1(cPerg, '02', "Peso Def (Kg)", "Peso Def (kg)", "Peso Def (Kg)", 'mv_ch2', 'N', nTamPeso, nDecPeso, 0, 'G', '', ''   , '', '', 'mv_par02',"","","","",;
		"","","","","","","","","","","","",aHelpPor,aHelpEng,aHelpSpa) //"Peso Def (g)"
return
 //-------------------------------------------------------------------
/*/{Protheus.doc} LJ900APr
Criação da rotina de processamento dos produtos
@param   	cPerg - Nome da Pergunta
@author  Varejo
@version 	P11.8
@since   	16/07/2015
@obs     
@sample 	LJ900APr(cTrab, aMasc, @cGrdAnt, @aGrades) 
/*/
//-------------------------------------------------------------------	
 Static Function LJ900ADr(cTrab, aMasc, cGrdAnt, aGrades, lValidVar, nPosGrd)
 Local cMsg := ""
 Local cProdPai := ""
 
 
If !Empty(Substr((cTrab)->B1_COD, aMasc[1]+1,aMasc[2] )) .OR. !Empty(Substr((cTrab)->B1_COD, aMasc[1]+aMasc[2]+1, aMasc[3]))

	
	If cGrdAnt <> AllTrim((cTrab)->B4_COD)
		cGrdAnt := AllTrim((cTrab)->B4_COD)
		nPosGrd := aScan(aGrades, { | g| g[1] == cGrdAnt})
		If nPosGrd == 0
			aAdd(aGrades, { cGrdAnt, "" })
			nPosGrd := Len(aGrades)
		EndIf
	EndIf	
	If Empty(aGrades[nPosGrd, 02])
		//realiza a Busca do Pai
		cProdPai := ""
		cProdPai := LJ900APC( (cTrab)->B4_COD, (cTrab)->B1_COD, aMasc[1])
		aGrades[nPosGrd, 02] := cProdPai //Pai gravado na grade, supõe-se que esteja validado
	EndIf
	If Empty(aGrades[nPosGrd, 02])
		cProdPai := LJ900APV( (cTrab)->B4_COD, (cTrab)->B1_COD, aMasc[1], aMasc[2], aMasc[3], lValidVar)				
		aGrades[nPosGrd, 02] := cProdPai
	EndIf
	If !Empty(aGrades[nPosGrd, 02]) .and. aGrades[nPosGrd, 02] <>  ".F." //Produto-pai, localizado

		SB1->(DbGoTo( (cTrab)->SB1REC))
		If Lj900XRL("SB1", .F. , "U_LJ900A") //Função de Bloqueio de Registro
			SB1->B1_PRODPAI := aGrades[nPosGrd, 02]
			SB1->(MsUnlock())
			cMsg := ">> Atualizado Pai do Produto "+ AllTrim((cTrab)->B1_COD) + " Pai: " + aGrades[nPosGrd, 02]		
		Else
			cMsg := ">> <<Falha>> ao atualizar Pai do Produto "+ AllTrim((cTrab)->B1_COD) + " Pai: " + aGrades[nPosGrd, 02]		
			
		EndIf
		Lj900XLg(cMsg, (cTrab)->B1_COD)
		
	Else
		cMsg := ">> Falha ao identificar Pai do Produto "+ AllTrim((cTrab)->B1_COD) + " Pai Identificado: " + aGrades[nPosGrd, 02]		
		
		Lj900XLg(cMsg, (cTrab)->B1_COD)
	EndIf
Else
	cMsg := ">> Produto ["+ AllTrim((cTrab)->B1_COD) + "] com linha/coluna em branco, grade está inválida. Produto-pai não atualizado."
	
	Lj900XLg(cMsg, (cTrab)->B1_COD)		
EndIf
		
 
Return


 //-------------------------------------------------------------------
/*/{Protheus.doc} Lj900ADP
Criação da rotina de processamento de produtos - complemento de produto
@param   	cPerg - Nome da Pergunta
@author  Varejo
@version 	P11.8
@since   	16/07/2015
@obs     
@sample 	Lj900ADP(cFilSB5, cAlias, cEcFlag, nPeso)
/*/
//-------------------------------------------------------------------	
Static Function Lj900ADP(cFilSB5, cAlias, cEcFlag, nPeso)
Local lLock := .F.
Local cMsg := ""

		
If SB5->(DbSeek(cFilSB5 + (cAlias)->B1_COD)) 	
	cMsg := "Atualizado complemento de Produto - Pai "+ AllTrim((cAlias)->B1_COD) 	
	lLock := Lj900XRL("SB5", .F. , "U_LJ900AD") 
Else	
	cMsg := "Criado complemento de Produto - Pai "+ AllTrim((cAlias)->B1_COD) 	
	lLock := Lj900XRL("SB5", .T. , "U_LJ900AD") 
	If lLock
		SB5->B5_FILIAL := cFilSB5
		SB5->B5_COD := (cAlias)->B1_COD
	EndIf
EndIf

If lLock
 	If Empty(SB5->B5_ECFLAG)
 		SB5->B5_ECFLAG := cEcFlag
 	EndIf
 	
 	SB5->B5_ECDTEX := ""
 	
 	If Empty(SB5->B5_ECDESCR)
 		SB5->B5_ECDESCR := (cAlias)->B1_DESC
 	EndIf 	
  	If Empty(SB5->B5_CEME)
 		SB5->B5_CEME := (cAlias)->B1_DESC
 	EndIf 	
   	If SB5->B5_PESO = 0
 		SB5->B5_PESO := nPeso
 	EndIf 	
    If Empty(SB5->B5_ECTITU)
 		SB5->B5_ECTITU :=(cAlias)->B1_DESC
 	EndIf 	
	 	
	SB5->(MsUnLock())
Else
	cLog := "<<Falha>> na Criação/Atualização Complemento de Produto - Pai "+ AllTrim((cAlias)->B1_COD) 	
EndIf	
Lj900XLg(cMsg, (cAlias)->B1_COD)

Return

 //-------------------------------------------------------------------
/*/{Protheus.doc} Lj900ADP
Criação da rotina de processamento de produtos - Dados do produto
@param   	cPerg - Nome da Pergunta
@author  Varejo
@version 	P11.8
@since   	16/07/2015
@obs     
@sample 	Lj900AD2(cFilSB0, cAlias, cEcFlag)
/*/
//-------------------------------------------------------------------	
Static Function Lj900AD2(cFilSB0, cAlias, cEcFlag)
Local cMsg := ""
Local lLock := .F.

If SB0->(DbSeek(cFilSB0 + (cAlias)->B1_COD)) 	
	cMsg := "Atualizado dados EC do Produto-Filho   "+ AllTrim((cAlias)->B1_COD) 
	lLock := Lj900XRL("SB0", .F. , "U_LJ900AD") 
Else	
	cMsg := "Criado dados EC do Produto-Filho   "+ AllTrim((cAlias)->B1_COD) 
	lLock := Lj900XRL("SB0", .T. , "U_LJ900AD") 
	If lLock
		SB0->B0_FILIAL := cFilSB0
		SB0->B0_COD := (cAlias)->B1_COD
	EndIf
EndIf
If lLock
	SB0->B0_ECTITU := (cAlias)->B1_DESC
	SB0->B0_ECFLAG := cEcFlag
	SB0->B0_ECDTEX := ""
	SB0->(MsUnLock()) 
Else
	cLog := "<<Falha>> na Criação/Atualização dados EC do Produto-Filho   "+ AllTrim((cAlias)->B1_COD) 
EndIf	

Lj900XLg(cMsg, (cAlias)->B1_COD)	


Return

 //-------------------------------------------------------------------
/*/{Protheus.doc} Lj900AB4
Criação da rotina de consulta de produtos a serem atualizados o pai
@param   	cPerg - Nome da Pergunta
@author  Varejo
@version 	P11.8
@since   	16/07/2015
@obs     
@sample 	Lj900AB4(cTrab, nTotRec, aMasc)
/*/
//-------------------------------------------------------------------	
Static Function Lj900AB4(cTrab, nTotRec, aMasc)
Local cQuery := ""

	cQuery := "SELECT B4_COD, B1_COD, SB1.R_E_C_N_O_ AS SB1REC FROM " +;
				RetSQLName("SB1") +" SB1, " + ;
				RetSQLName("SB4") + " SB4 WHERE "
	cQuery += "SUBSTRING(B1_COD,1," +Str(aMasc[1]) +") =  " + "SUBSTRING(B4_COD,1," +Str(aMasc[1]) +")   "  
	cQuery += "AND SB4.D_E_L_E_T_ = '' "+;
				" AND B4_FILIAL = '" +xFilial("SB4") +"' "
	cQuery += " AND SB1.D_E_L_E_T_ = '' "+;
				" AND B1_FILIAL = '" +xFilial("SB1") +"' " + ;
				"AND (B1_PRODPAI = ''   OR B1_PRODPAI  = '" +space(SB1->(Tamsx3("B1_PRODPAI")[1]))+ "')"+;
				" AND B1_GRADE = 'S' "+;
				"AND SB1.B1_MSBLQL <> '1'"+;							
				"ORDER BY B4_COD, B1_COD "
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTrab,.T.,.T.)
	
	nTotRec := Lj900XRC( cTrab, "U_LJ900A")


Return

			 