#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "apwizard.ch"  
#INCLUDE 'FWBROWSE.CH'

#DEFINE X3_USADO_EMUSO "���������������"
#DEFINE X3_USADO_NAOUSADO "���������������"   
#DEFINE X3_OBRIGAT "��" 
#DEFINE X3_NAOOBRIGAT "��"
#DEFINE X3_RESER "�A"

#DEFINE PULALINHA CHR(13)+CHR(10)

Static aPerg := {}
Static aResp := {}

/*���������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Funcao    � UPATF050 � Autor Felipe Cunha  	      	� Data � 01/04/14 ���
�������������������������������������������������������������������������Ĵ��
���Descricao � 															        ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � UPATF050                                                   ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
���������������������������������������������������������������������������*/
User Function UPDATF050()

Local lGravouLog 		:= .F.
Local oOk        		:= LoadBitmap( GetResources(), "LBOK" )
Local oNOk       		:= LoadBitmap( GetResources(), "LBNO" )

Private cApresenta 	:= ''
Private cLogUpdate 	:= ''

Private lConcordo  	:= .F.

Private lChkTerm		:= .F.

Private aSelFil := {}

//-----------------------------------------------------
//Mensagem de Apresenta��o                             
//-----------------------------------------------------                
cApresenta := "O procedimento de actualiza��o ajustar� os registros das tabelas de Movimentos do Ativo(SN4) e Tipos de Ativos(SN3) gerados pela rotina de Calculo mensal(ATFA050)."


//-----------------------------------------------------
//Termo de Aceite
//-----------------------------------------------------
cTerAceite := "Antes que sua atualiza��o inicie, voc� deve ler e aceitar os termos e as condi��es a seguir. Ap�s aceit�-los, voc� pode prosseguir com a atualiza��o." + PULALINHA	//"Antes que sua atualiza��o inicie, voc� deve ler e aceitar os termos e as condi��es a seguir. Ap�s aceit�-los, voc� pode prosseguir com a atualiza��o."
cTerAceite += PULALINHA


//-----------------------------------------------------
// Desliga Refresh no Lock do Top
//-----------------------------------------------------
#IFDEF TOP
	TCInternal(5,'*OFF') 
#ENDIF

//-----------------------------------------------------
// Painel 1 - Tela inicial do Wizard 		            
//-----------------------------------------------------
oWizard := APWizard():New("Wizard Atualiza��o Movimentos do Ativo Fixo"/*<chTitle>*/,; // "Wizard Atualiza��o Movimentos do Ativo Fixo"
                          	/* <.chMsg.>    */ "",;
                          	/* <.cTitle.>   */ "",;
								/* <.cText.>    */ cApresenta ,; 
								/* <.bNext.>    */ {||.T.},;
								/* <.bFinish.>  */ {||.T.},;
								/* <.lPanel.>   */ .F.,;
								/* <.cResHead.> */ ,;
								/* <.bExecute.> */ ,; 
								/* <.lNoFirst.> */ ,;
								/* <aCoord.>	  */)
								
//-----------------------------------------------------
// Painel 2 - Termo de Aceite         
//-----------------------------------------------------
oWizard:NewPanel(	/*<chTitle> */ "Termo de Aceite" ,;
					/*<chMsg>   */ "Antes que sua atualiza��o inicie, voc� deve ler e aceitar os termos e as condi��es a seguir. Ap�s aceit�-los, voc� pode prosseguir com a atualiza��o.",; // "Antes que sua atualiza��o inicie, voc� deve ler e aceitar os termos e as condi��es a seguir. Ap�s aceit�-los, voc� pode prosseguir com a atualiza��o."
					/*<bBack>   */ {||.T.},;
					/*<bNext>   */ {||lChkTerm},;
					/*<bFinish> */ {||.T.},;
					/*<.lPanel.>*/ .F.    ,;
					/*<bExecute>*/ {|| UpdAtfP2()})
					
//-----------------------------------------------------
// Painel 3 - Parametros       
//-----------------------------------------------------
oWizard:NewPanel(	/*<chTitle> */ "Parametros" 	,;
					/*<chMsg>   */ ""					,;
					/*<bBack>   */ {||.T.}			,;
					/*<bNext>   */ {||UpdAtfPros(),.T.}	,;
					/*<bFinish> */ {||.T.}			,;
					/*<.lPanel.>*/ .T.    			,;
					/*<bExecute>*/ {|| UpdAtfP3()})
					
//-----------------------------------------------------
// Painel 4 - Processamento       
//-----------------------------------------------------
oWizard:NewPanel(	/*<chTitle> */ "Confirma Processamento" ,;
					/*<chMsg>   */ ,;
					/*<bBack>   */ {||.T.},;
					/*<bNext>   */ {||.T.},;
					/*<bFinish> */ {||UpdAtfTOk()},;
					/*<.lPanel.>*/ .T.    ,;
					/*<bExecute>*/ {|| UpdAtfP4()})
								
oWizard:Activate(	.T./*<.lCenter.>*/,;
					 	{ || .T. }/*<bValid>*/, ;
						{ || .T. }/*<bInit>*/, ;
						{ || .T. }/*<bWhen>*/ )

Return


/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �UpdAtfTerm  �Autor  �Felipe Cunha       � Data �  01/04/14  ���
�������������������������������������������������������������������������͹��
���Desc.     � Termo de Aceite											  		 ���
�������������������������������������������������������������������������͹��
���Uso       � AP                                                         ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function UpdAtfP2()
Local oPanel		:= Nil
Local oCheckTerm
Local oScrolTerm
Local bTerm 


bTerm := {|| 	"     Antes que sua atualiza��o inicie, voc� deve ler e aceitar os termos e as condi��es a seguir." 	+; 
				" Ap�s aceit�-los, voc� pode prosseguir com a atualiza��o."                                         	+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"ATEN��O: LEIA COM ATEN��O ANTES DE PROSSEGUIR COM A ATUALIZA��O" 											+;
				PULALINHA 																											+;
				PULALINHA                 																						+;
				"ACORDO DE LICEN�A DE SOFTWARE PARA USU�RIO FINAL ('ACORDO')" 												+;
				PULALINHA 																											+;
				PULALINHA                 																						+;
				"TERMOS E CONDI��ES"                                                                                 	+;
				PULALINHA                 																						+;
				"ADVERT�NCIAS LEGAIS: AO CLICAR NA OP��O 'SIM, LI E ACEITO O TERMO ACIMA' NO FINAL DESTA JANELA,"    	+; 
				" VOC� INDICA QUE LEU E CONCORDOU COM TODOS OS TERMOS DESTE ACORDO E QUE CONSENTE EM SER REGIDO POR" 	+;
				" ESTE ACORDO E TORNAR-SE PARTE DELE.  A TOTVS EST� DISPOSTA A DISPONIBILIZAR ESTE AJUSTE PARA VOC�" 	+;
				" APENAS SOB A CONDI��O DE QUE VOC� CONCORDE COM TODOS OS TERMOS CONTIDOS NESTE ACORDO. SE VOC� N�O"	+;
				" CONCORDA COM TODOS OS TERMOS DESTE ACORDO, CLIQUE NO BOT�O 'CANCELAR' E N�O PROSSIGA COM O AJUSTE."	+;
				PULALINHA 																											+;
				"O ACORDO A SEGUIR � UM ACORDO LEGAL ENTRE VOC� (O USU�RIO FINAL, SEJA UM INDIV�DUO OU ENTIDADE),"	+;
				" E A TOTVS S/A. (PROPRIAMENTE DITA OU SUAS LICENCIADAS). " 												+;
				PULALINHA                 																						+;
				"ESTE SOFTWARE � LICENCIADO PELA TOTVS PARA VOC�, E QUALQUER RECEPTOR SUBSEQ�ENTE DO SOFTWARE,"		+; 
				" SOMENTE PARA USO SEGUNDO OS TERMOS ESTABELECIDOS NESTE DOCUMENTO. " 									+;
				PULALINHA 																											+;
				PULALINHA                 																						+;
				"PREMISSAS DE UTILIZA��O: Antes de executar esta rotina � obrigat�ria a realiza��o de uma c�pia de" 	+;
				" seguran�a geral do sistema Protheus (bin�rio, RPO, dicion�rios SXs e banco de dados). Fa�a testes" 	+;
				" de performance e planeje-se antes de executar esta atualiza��o, pois ela requer acesso exclusivo" 	+;
				" �s tabelas do sistema (ou seja: nenhum usu�rio poder� acessar o sistema) durante toda a sua"			+;
				" execu��o, que pode demorar v�rias horas para ser finalizada! Depois de iniciada esta rotina n�o"	+;
				" poder� ser interrompida! Qualquer tipo de interrup��o (ex.:falta de energia, problemas de hardware"	+;
				" , problemas de rede, etc.) poder� danificar todo o sistema! Neste caso deve-se realizar a"			+;
				" restaura��o da c�pia de seguran�a feita imediatamente antes do inicio da atualiza��o antes de" 		+;
				" execut�-la novamente." 																						+;
				PULALINHA 																											+;
				PULALINHA                 																						+;
				"CONCESS�O DE LICEN�A: A TOTVS lhe concede uma licen�a limitada, n�o-exclusiva e revog�vel para usar"	+;
				" a vers�o de c�digo execut�vel da Atualiza��o do m�dulo Ativo Fixo denominada UPDATF050,"	+;
				" eximindo-se de qualquer dado resultante da utiliza��o deste." 											+;
				PULALINHA 																											+;
				PULALINHA 																											+;  
				"DIREITOS AUTORAIS: O Software � propriedade da TOTVS e est� protegido por leis de direitos autorais"	+;
				" do Brasil e disposi��es de tratados internacionais.  Voc� reconhece que n�o lhe ser� transferido"	+;
				" qualquer direito a qualquer propriedade intelectual do Software. " 										+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"LIMITA��ES: Exceto se explicitamente disposto em contr�rio neste Acordo, voc� n�o pode:"				+;
				PULALINHA 																											+;
				"a) modificar o Software ou criar trabalhos derivados do mesmo; "											+;
				PULALINHA 																											+;
				"b) descompilar, desmontar, fazer engenharia reversa, ou de outras maneiras tentar alterar o c�digo"	+;
				"-fonte do Software;"																							+;
				PULALINHA 																											+;
				"c) copiar (exceto para fazer uma c�pia de backup), redistribuir, impedir, vender, alugar, arrendar"	+;
				", sublicenciar, atribuir ou de outras maneiras transferir seus direitos ao Software; ou " 			+;
				PULALINHA 																											+;				
				"d) remover ou alterar qualquer marca registrada, logotipo, registro ou outras advert�ncias"			+;
				" propriet�rias no Software.  Voc� pode transferir todos os seus direitos ao Software regidos por"	+;
				" este Acordo para outra pessoa transferindo-lhe, permanentemente, o computador pessoal no qual o"	+;
				" Software est� instalado, contanto que voc� n�o retenha nenhuma c�pia do Software e que o receptor"	+;
				" concorde com todos os termos deste Acordo. " 																+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"ATIVIDADES DE ALTO RISCO: O Software n�o � tolerante a falhas e n�o foi projetado, fabricado ou"		+;
				" desenvolvido para uso em ambientes perigosos que requerem desempenho � prova de falhas, como na"	+;
				" opera��o de instala��es nucleares, navega��o de aeronaves ou sistemas de comunica��o, controle de"	+;
				" tr�fego a�reo, dispositivos m�dicos implantados em seres humanos, m�quinas externas de suporte �"	+;
				" vida humana, dispositivos de controle de explosivos, submarinos, sistemas de armas ou controle de"	+;
				" opera��o de ve�culos motorizados nos quais a falha do Software poderia levar diretamente � morte,"	+;
				" danos pessoais ou danos f�sicos ou ambientais graves ('Atividades de Alto Risco'). Voc� concorda"	+;
				" em n�o usar o Software em Atividades de Alto Risco. " 													+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"REN�NCIA �S GARANTIAS: A TOTVS n�o garante que o Software satisfar� suas exig�ncias, que a opera��o"	+;
				" do mesmo ser� ininterrupta ou livre de erros, ou que todos os erros de Software ser�o corrigidos."	+;
				" Todo o risco no que se refere � qualidade e ao desempenho do Software decorre por sua conta."		+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"O SOFTWARE � FORNECIDO 'COMO EST�' E SEM GARANTIAS DE QUALQUER TIPO, EXPRESSAS OU IMPL�CITAS,"		+;
				" INCLUINDO, MAS N�O SE LIMITANDO A, GARANTIAS DE T�TULOS, N�O-VIOLA��O, COMERCIALIZA��O E ADEQUA��O"	+;
				" PARA UMA FINALIDADE EM PARTICULAR.  NENHUMA INFORMA��O OU CONSELHO VERBAL OU POR ESCRITO,"			+;
				" FORNECIDOS PELA TOTVS, SEUS FUNCION�RIOS, DISTRIBUIDORES, REVENDEDORES OU AGENTES AUMENTAR�O O"		+;
				" ESCOPO DAS GARANTIAS ACIMA OU CRIAR�O QUALQUER GARANTIA NOVA." 											+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"LIMITA��O DE RESPONSABILIDADE: MESMO QUE QUALQUER SOLU��O FORNECIDA NA GARANTIA FALHE EM SEU"			+;
				" PROP�SITO ESSENCIAL, EM NENHUM EVENTO A TOTVS TER� OBRIGA��ES POR QUALQUER DANO ESPECIAL,"			+;
				" CONSEQ�ENTE, INDIRETO OU SEMELHANTE, INCLUINDO PERDA DE LUCROS OU DADOS, DERIVADOS DO USO OU"		+;
				" INABILIDADE DE USAR O SOFTWARE, OU QUAISQUER DADOS FORNECIDOS, MESMO QUE A TOTVS OU OUTRA PARTE"	+;
				" TENHA SIDO AVISADA DA POSSIBILIDADE DE TAL DANO, OU EM QUALQUER REIVINDICA��O DE QUALQUER OUTRA"	+;
				" PARTE." 																											+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"ALGUMAS JURISDI��ES N�O PERMITEM A LIMITA��O OU EXCLUS�O DE RESPONSABILIDADE POR DANOS INCIDENTAIS"	+;
				" OU CONSEQ�ENTES; PORTANTO, A LIMITA��O OU EXCLUS�O ACIMA PODE N�O SE APLICAR AO SEU CASO." 			+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"TERMO: Este Acordo � v�lido at� ser terminado.  Este Acordo terminar�, e a licen�a concedida a voc�"	+;
				" por este Acordo ser� revogada, imediatamente, sem qualquer advert�ncia da TOTVS, se voc� n�o"		+;
				" obedecer a qualquer disposi��o deste Acordo. Ao t�rmino do mesmo, voc� dever� destruir o Software."	+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"ACORDO INTEGRAL: Este Acordo constitui o acordo integral entre voc� e a TOTVS, no que se refere ao"	+;
				" Software licenciado, e substitui todas as comunica��es, as representa��es, as compreens�es e os"	+;
				" acordos anteriores, verbais ou por escrito, entre voc� e a TOTVS relativos a este Software.  Este"	+;
				" Acordo n�o pode ser modificado ou renunciado, exceto por escrito e assinado por uma autoridade ou"	+;
				" outro representante autorizado de cada parte." 															+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"Se qualquer disposi��o for considerada inv�lida, todas as outras permanecer�o v�lidas, a menos que"	+;
				" impe�a o prop�sito de nosso Acordo.  A falha de qualquer parte em refor�ar qualquer direito"			+;
				" concedido neste documento, ou em entrar em a��o contra a outra parte no caso de qualquer viola��o,"	+;
				" n�o ser� considerada uma desist�ncia � subseq�ente execu��o dos direitos ou � subseq�ente a��o no"	+;
				" caso de futuras viola��es." }

oPanel   	:= oWizard:oMPanel[oWizard:nPanel]

oScrolTerm	:= TScrollBox():New(oPanel,005,005,125,291,.T.,.T.,.T.)
oCheckTerm	:= TCheckBox():New( 135,008,"Sim, li e aceito os termos acima.",bSETGET(lChkTerm)		,oPanel,150,009,,,,,,,,.T.,,,) //"Sim, li e aceito os termos acima."

 // Cria objetos para teste do Scroll   
oFont 	:= TFont():New('Courier new',,-12,.T.)   
oSay1	:= TSay():New(008,008,bTerm, oScrolTerm,,oFont,,,,.T.,CLR_BLUE,CLR_WHITE,270,900) 

Return

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �UpdAtfTerm  �Autor  �Felipe Cunha       � Data �  01/04/14  ���
�������������������������������������������������������������������������͹��
���Desc.     � Termo de Aceite											  		 ���
�������������������������������������������������������������������������͹��
���Uso       � AP                                                         ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function UpdAtfP4()
Local oPanel		:= Nil
Local oCheckTerm
Local oScrolTerm
Local bTerm 


bTerm := {|| 	"Esta rotina ir� ajustar os Movimentos do Ativo(SN4) a partir dos parametros      	" +;
				"informado e os valores acumulados de deprecia��o na tabela Tipos de Ativos(SN3) 	" +;
				"gerados pela rotina Calculo Mensal(ATFA050)												" +;
				PULALINHA 																						+;
				PULALINHA 																						+; 
				"Antes de processar o ajuste tenha certeza que o backup do ambiente foi executado.	" +;
				PULALINHA 																						+;
				PULALINHA 																						+;
				"Confirma ?																					"}			

oPanel   	:= oWizard:oMPanel[oWizard:nPanel]

oScrolTerm	:= TScrollBox():New(oPanel,005,005,125,291,.T.,.T.,.T.)

 // Cria objetos para teste do Scroll   
oFont 	:= TFont():New('Courier new',,-12,.T.)   
oSay1	:= TSay():New(008,008,bTerm, oScrolTerm,,oFont,,,,.T.,CLR_BLUE,CLR_WHITE,270,900) 

Return

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �UpdAtfTerm  �Autor  �Felipe Cunha       � Data �  01/04/14  ���
�������������������������������������������������������������������������͹��
���Desc.     � Termo de Aceite											  		 ���
�������������������������������������������������������������������������͹��
���Uso       � AP                                                         ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function UpdAtfP3()
Local oPanel		:= Nil
Local dDataIni		:= FirstDay(dDataBase)
Local dDataFin		:= LastDay(dDataBase)

aPerg := {}
aResp := {}

oPanel   	:= oWizard:oMPanel[oWizard:nPanel]
aAdd(aPerg,{1,"Data De:"				,dDataIni,""	,"","",,50,.T.}) 				//"Periodo Inicial da Escritura��o: "
aAdd(aPerg,{1,"Data Ate"				,dDataFin,""	,"","",,50,.T.}) 				//"Periodo Final da Escritura��o: "
aAdd(aPerg,{3,"Seleciona Filiais"	, 1	, {"Sim", "N�o"}	, 100,"", .T. })		//"Tipos de saldo"###"1-Normais"###"2-Conciliados"###"3-N�o conciliados"
aResp := {dDataIni,dDataFin, 1}
ParamBox(aPerg,"",aResp,,,,,,oPanel) 

Return

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �UpdAtfPros  �Autor  �Felipe Cunha       � Data �  01/04/14  ���
�������������������������������������������������������������������������͹��
���Desc.     � Termo de Aceite											  		 ���
�������������������������������������������������������������������������͹��
���Uso       � AP                                                         ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function UpdAtfPros()


If aResp[3] == 1
	aSelFil := AdmGetFil()
Else
	aSelFil := {cFilAnt}
EndIf

Return .T.

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �UpdAtfTOk  �Autor  �Felipe Cunha       � Data �  01/04/14  ���
�������������������������������������������������������������������������͹��
���Desc.     � Termo de Aceite											  		 ���
�������������������������������������������������������������������������͹��
���Uso       � AP                                                         ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function UpdAtfTOk()

Local dDataIni 	:= aResp[1] 				//Movimentos SN4 - Data De
Local dDataFim 	:= aResp[2] 				//Movimentos SN4  - Data Ate
Local cAliasQry	:= ''						//Movimentos SN4  - Qry Movimentos
Local cQuery 		:= ''						//Movimentos SN4  - Qry Movimentos
Local cOcorr		:= ''						//Movimentos SN4  - Codigo Ocorrencia
Local aValDepr 	:= AtfMultMoe(,,{|x| 0})	//Movimentos SN4  - Valor de Deprecia��o
Local aDadosComp 	:= {}						//Movimentos SN4  - Taxa Moeda
Local aData		:= {}						//Movimentos SN4  - Periodos de Analise
Local nX			:= 0						//Movimentos SN4  - Sequencial			
Local cTmpSN4Fi1								//Movimentos SN4  - Temporario para Filial
Local nRecnoSN4	:= 0						//Movimentos SN4  - Recno
Local aAreaSN4	
Local nInc			:= 0

Local aStruct			:= {}					//Cadastro SN3  - Estrutura Tabela Temporaria 
Local __cTmpBD		:= ''					//Cadastro SN3  - Nome Arquivo Temporario
Local cAliasQrySN3	:= ''					//Cadastro SN3  - Qry Cadastro
Local cQuerySN3 		:= ''					//Cadastro SN3  - Qry Cadastro
Local dDataDe			:= ''					//Cadastro SN3  - Data De (01/01/XXXX)
Local dDataAte		:= ''					//Cadastro SN3  - Data De (31/12/XXXX)

//-------------------------------------------------------------------------------
// Atualiza SN4
//-------------------------------------------------------------------------------

//Carrega Periodos a serem processados
While dDataFim <= aResp[2]
	 
	dDataIni 	:= FirstDay(dDataIni)
	dDataFim 	:= LastDay(dDataIni)
	
	aAdd(aData, { DTOS(dDataIni),DTOS(dDataFim) } )
	
	//Incrementa 1 mes
	dDataIni 	:= (dDataFim + 1)

	If dDataIni > aResp[2]
		Exit
	EndIf
EndDo


#IFDEF TOP

For nInc := 1 To Len( aSelFil )

	cFilAnt := aSelFil[nInc]
		
	For nX := 1 to Len(aData)

		cAliasQry 	:= GetNextAlias()
		
		If nX > 1
			cQuery += " UNION " 
			cQuery += "SELECT SN4.R_E_C_N_O_ SN4RECNO 																	"
		Else
			cQuery := "SELECT SN4.R_E_C_N_O_ SN4RECNO 																	"
		EndIf
	
		cQuery += "FROM "+RetSqlName("SN4")+" SN4 																		"	
		cQuery += "WHERE 																										"	
		cQuery += "	SN4.N4_FILIAL " + GetRngFil( aSelFil ,"SN4", .T., @cTmpSN4Fi1) + " AND						"		
		cQuery += "	SN4.N4_DATA    >= '" + aData[nX][1]  + "' AND 													"
		cQuery += "	SN4.N4_DATA    <= '" + aData[nX][2]  + "' AND 													"
		cQuery += "	SN4.N4_MOTIVO  = '  ' AND 																			"
		cQuery += "	SN4.N4_TIPOCNT = '3'  AND 																			"
		cQuery += "	SN4.D_E_L_E_T_ = ' '  AND 																			"
		cQuery += "	NOT EXISTS ( 																							"
		cQuery += "				SELECT SN4.R_E_C_N_O_ SN4RECNO	 														"
		cQuery += "				FROM "+RetSqlName("SN4")+" SN4b	 														"
		cQuery += "				WHERE 																						"
		cQuery += "				SN4b.N4_FILIAL = '" + xFilial("SN4") + "' AND											"
		cQuery += "				SN4b.N4_DATA    >= '" + aData[nX][1]   + "' AND										"
		cQuery += "				SN4b.N4_DATA    <= '" + aData[nX][2]   + "' AND										"
		cQuery += "				SN4b.N4_MOTIVO  = '  ' AND 																"
		cQuery += "				SN4b.N4_TIPOCNT = '4'  AND 																"
		cQuery += "				SN4b.D_E_L_E_T_ = ' ' AND 																"
		cQuery += "				SN4b.N4_FILIAL  = SN4.N4_FILIAL AND													"
		cQuery += "				SN4b.N4_CBASE   = SN4.N4_CBASE AND														"
		cQuery += "				SN4b.N4_ITEM    = SN4.N4_ITEM AND 														"
		cQuery += "				SN4b.N4_TIPO    = SN4.N4_TIPO  	 														"		
		cQuery += "               	 ) 																						"
	Next nX
			
	cQuery := ChangeQuery(cQuery)
	MsAguarde({|| dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasQry,.T.,.T.)},"Selecionando Registros...") 
	
	//Posiciona no primeiro registro
	( cAliasQry )->( dbGotop() )
	
	While ( cAliasQry )->( !Eof() )
		
		//cFilAnt := SN4->N4_FILAL
		
		//Posiciono o SN4 no Registro filtrado 
		SN4->(dbGoTo( ( cAliasQry )->SN4RECNO ) )
		
		//Guardo a Area
		aAreaSN4	:= SN4->( GetArea() )
		
		//Carrega valores em todas as moedas
		For nX := 1 to Len(aValDepr)
			aValDepr[nX] := SN4->&( "N4_VLROC" + cValToChar(nX) )
		Next nX
		
		//Verifica a Ocorrencia
		cOcorr := IIF( SN4->N4_TIPO $ "10,12,14,50,51,52,53,54", "20", IIF(SN4->N4_TIPO == "07","10",IIF(SN4->N4_TIPO=="08","12",IIF(SN4->N4_TIPO == "09","11","06"))))
		
		//Taxa de Deprecia��o
		Afill(aDadosComp, SN4->N4_TXDEPR) 
		
		//Gera Movimento Faltante
		nRecnoSN4 := SN4->(RECNO())		
		ATFXMOV(cFilAnt,SN4->N4_IDMOV,SN4->N4_DATA,cOcorr,SN4->N4_CBASE,SN4->N4_ITEM,SN4->N4_TIPO,"0",SN4->N4_SEQ,SN4->N4_SEQREAV,"4",SN4->N4_QUANTD,SN4->N4_TPSALDO,,aValDepr,aDadosComp)
		
		//Retorno a Area
		RestArea(aAreaSN4)		
		dbSelectArea( cAliasQry ) 
		
		( cAliasQry) ->(dbSkip())
	
	Enddo
	
	CtbTmpErase(cTmpSN4Fi1)
		
	//-------------------------------------------------------------------------------
	// Atualiza SN3
	//-------------------------------------------------------------------------------	
	cAliasQrySN3 := GetNextAlias()
	cQuerySN3 := "Select SN4.N4_FILIAL FILIAL,		   "
	cQuerySN3 += "  		SN4.N4_CBASE BASE,      "
	cQuerySN3 += "		SN4.N4_ITEM ITEM,       "
	cQuerySN3 += "		SN4.N4_TIPO TIPO,       "	
	cQuerySN3 += "		SN4.N4_TIPOCNT TIPOCNT, "
	cQuerySN3 += "		SUM(N4_VLROC1)VALOR1,   "
	cQuerySN3 += "		SUM(N4_VLROC2)VALOR2,   "
	cQuerySN3 += "		SUM(N4_VLROC3)VALOR3,   "
	cQuerySN3 += "		SUM(N4_VLROC4)VALOR4,   "
	cQuerySN3 += "		SUM(N4_VLROC5)VALOR5,   "
	cQuerySN3 += "		MAX(N4_DATA)DATA		   "
	cQuerySN3 += "		FROM " + RetSqlName("SN4" )+ " SN4 "// +  __cTmpBD + " TEMP "
	cQuerySN3 += "		WHERE  SN4.N4_TIPOCNT = '4' AND         "
	cQuerySN3 += "				SN4.N4_FILIAL = '" + xFilial("SN4") + "' AND "
	cQuerySN3 += "				SN4.D_E_L_E_T_ = ''           "
	cQuerySN3 += "		GROUP BY SN4.N4_FILIAL,					 " 
	cQuerySN3 += "				SN4.N4_CBASE,    		            "
	cQuerySN3 += "				SN4.N4_ITEM,                     "
	cQuerySN3 += "				SN4.N4_TIPO,                     "
	cQuerySN3 += "				SN4.N4_TIPOCNT                   "
	
	cQuerySN3 := ChangeQuery(cQuerySN3)
	MsAguarde({|| dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuerySN3),cAliasQrySN3,.T.,.T.)},"Atualizando Registros SN3...") 
	
	//Posiciona no primeiro registro
	( cAliasQrySN3 )->( dbGotop() )
	
	While ( cAliasQrySN3 )->( !Eof() )
		//If (SN4->(MsSeek( xFilial("SN4")+ (cAliasQrySN3)->BASE + (cAliasQrySN3)->ITEM + (cAliasQrySN3)->TIPO + (cAliasQrySN3)->DATA ) ) )		
			//Posiciona na SN3
			If (SN3->(MsSeek( (cAliasQrySN3)->FILIAL + (cAliasQrySN3)->BASE + (cAliasQrySN3)->ITEM + (cAliasQrySN3)->TIPO ) ) )	
				RecLock("SN3", .F.)
					//Atualiza Valor de Deprecia��o Acumulada
					SN3->N3_VRDACM1 := (cAliasQrySN3)->VALOR1
					SN3->N3_VRDACM2 := (cAliasQrySN3)->VALOR2
					SN3->N3_VRDACM3 := (cAliasQrySN3)->VALOR3
					SN3->N3_VRDACM4 := (cAliasQrySN3)->VALOR4
					SN3->N3_VRDACM5 := (cAliasQrySN3)->VALOR5
					
					/*
					//Atualiza Valor da Ultima Deprecia��o
					SN3->N3_VRDMES1 :=  SN4->N4_VLROC1
					SN3->N3_VRDMES2 :=  SN4->N4_VLROC2
					SN3->N3_VRDMES3 :=  SN4->N4_VLROC3
					SN3->N3_VRDMES4 :=  SN4->N4_VLROC4
					SN3->N3_VRDMES5 :=  SN4->N4_VLROC5
					*/				
				MsUnlock() 
			EndIf
			( cAliasQrySN3) ->(dbSkip())
		//EndIf
	EndDo
	
	CtbTmpErase(cTmpSN4Fi1)
	
	
	
    //Atualiza Valor Acumulado ap�s a ultima virada Anual
    //Primeiro e Ultimo dia do Ano
    dDataDe	:= AllTrim( STR( YEAR( dDataBase ) ) ) + '0101'
    dDataAte 	:= AllTrim( STR( YEAR( dDataBase ) ) ) + '1231'
    cQuerySN3 := ''
    
    cAliasQrySN3 := GetNextAlias()
	cQuerySN3 := "Select  SN4.N4_FILIAL FILIAL,		   							"
	cQuerySN3 += "  		 SN4.N4_CBASE BASE,      						"
	cQuerySN3 += "		 SN4.N4_ITEM    ITEM,							"
	cQuerySN3 += "		 SN4.N4_TIPO    TIPO,    						"		    
	cQuerySN3 += "		 SN4.N4_TIPOCNT TIPOCNT,							"
	cQuerySN3 += "		 Sum(SN4.N4_VLROC1) VALOR1,						"
	cQuerySN3 += "		 Sum(SN4.N4_VLROC2) VALOR2,						"
	cQuerySN3 += "		 Sum(SN4.N4_VLROC3) VALOR3,						"
	cQuerySN3 += "		 Sum(SN4.N4_VLROC4) VALOR4,						"
	cQuerySN3 += "		 Sum(SN4.N4_VLROC5) VALOR5						"
	//cQuerySN3 += "		 FROM SN4010 SN4									"
	cQuerySN3 += "		FROM " + RetSqlName("SN4" )+ " SN4 			"
	cQuerySN3 += "		 WHERE  SN4.N4_TIPOCNT = '4'					"
	cQuerySN3 += "			 AND SN4.N4_FILIAL = '" + xFilial("SN4") + "'"	
	cQuerySN3 += "		    AND SN4.D_E_L_E_T_ = ''						"
	cQuerySN3 += "		    AND SN4.N4_DATA    >= '" + dDataDe  + "'	"
	cQuerySN3 += "		    AND SN4.N4_DATA    <= '" + dDataAte + "'	"
	cQuerySN3 += "		GROUP BY SN4.N4_FILIAL,					 		" 
	cQuerySN3 += "				SN4.N4_CBASE,    		           		"
	cQuerySN3 += "				SN4.N4_ITEM,								"
	cQuerySN3 += "				SN4.N4_TIPO,								"	
	cQuerySN3 += "				SN4.N4_TIPOCNT  							"
	
	
	cQuerySN3 := ChangeQuery(cQuerySN3)
	MsAguarde({|| dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuerySN3),cAliasQrySN3b,.T.,.T.)},"Atualizando Registros SN3...") 
	
	//Posiciona no primeiro registro
	( cAliasQrySN3b )->( dbGotop() )
	
	While ( cAliasQrySN3b )->( !Eof() )		
		//Posiciona na SN3
		If (SN3->(MsSeek( (cAliasQrySN3)->FILIAL + (cAliasQrySN3b)->BASE + (cAliasQrySN3b)->ITEM + (cAliasQrySN3b)->TIPO ) ) )	
			RecLock("SN3", .F.)
	
			//Atualiza Valor Acumulado ap�s a ultima virada Anual
			SN3->N3_VRDBAL1 := (cAliasQrySN3b)->VALOR1
			SN3->N3_VRDBAL2 := (cAliasQrySN3b)->VALOR2 
			SN3->N3_VRDBAL3 := (cAliasQrySN3b)->VALOR3
			SN3->N3_VRDBAL4 := (cAliasQrySN3b)->VALOR4
			SN3->N3_VRDBAL5 := (cAliasQrySN3b)->VALOR5
			
			MsUnlock() 
		EndIf
		( cAliasQrySN3b) ->(dbSkip())
	EndDo
	
	CtbTmpErase(cTmpSN4Fi1)
	
Next nInc
#ENDIF

Alert("Processo Finalizado com sucesso!!")		
	

Return .T.