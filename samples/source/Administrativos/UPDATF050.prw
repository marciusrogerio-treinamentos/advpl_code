#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "apwizard.ch"  
#INCLUDE 'FWBROWSE.CH'

#DEFINE X3_USADO_EMUSO "€€€€€€€€€€€€€€ "
#DEFINE X3_USADO_NAOUSADO "€€€€€€€€€€€€€€€"   
#DEFINE X3_OBRIGAT "ม€" 
#DEFINE X3_NAOOBRIGAT "ภ"
#DEFINE X3_RESER "A"

#DEFINE PULALINHA CHR(13)+CHR(10)

Static aPerg := {}
Static aResp := {}

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑฺฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤยฤฤฤฤฤฤยฤฤฤฤฤฤฤฤฤฤฟฑฑ
ฑฑณFuncao    ณ UPATF050 ณ Autor Felipe Cunha  	      	ณ Data ณ 01/04/14 ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณDescricao ณ 															        ณฑฑ
ฑฑรฤฤฤฤฤฤฤฤฤฤลฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤดฑฑ
ฑฑณ Uso      ณ UPATF050                                                   ณฑฑ
ฑฑภฤฤฤฤฤฤฤฤฤฤมฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤูฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿*/
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
//Mensagem de Apresenta็ใo                             
//-----------------------------------------------------                
cApresenta := "O procedimento de actualiza็ใo ajustarแ os registros das tabelas de Movimentos do Ativo(SN4) e Tipos de Ativos(SN3) gerados pela rotina de Calculo mensal(ATFA050)."


//-----------------------------------------------------
//Termo de Aceite
//-----------------------------------------------------
cTerAceite := "Antes que sua atualiza็ใo inicie, voc๊ deve ler e aceitar os termos e as condi็๕es a seguir. Ap๓s aceitแ-los, voc๊ pode prosseguir com a atualiza็ใo." + PULALINHA	//"Antes que sua atualiza็ใo inicie, voc๊ deve ler e aceitar os termos e as condi็๕es a seguir. Ap๓s aceitแ-los, voc๊ pode prosseguir com a atualiza็ใo."
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
oWizard := APWizard():New("Wizard Atualiza็ใo Movimentos do Ativo Fixo"/*<chTitle>*/,; // "Wizard Atualiza็ใo Movimentos do Ativo Fixo"
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
					/*<chMsg>   */ "Antes que sua atualiza็ใo inicie, voc๊ deve ler e aceitar os termos e as condi็๕es a seguir. Ap๓s aceitแ-los, voc๊ pode prosseguir com a atualiza็ใo.",; // "Antes que sua atualiza็ใo inicie, voc๊ deve ler e aceitar os termos e as condi็๕es a seguir. Ap๓s aceitแ-los, voc๊ pode prosseguir com a atualiza็ใo."
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณUpdAtfTerm  บAutor  ณFelipe Cunha       บ Data ณ  01/04/14  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Termo de Aceite											  		 บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function UpdAtfP2()
Local oPanel		:= Nil
Local oCheckTerm
Local oScrolTerm
Local bTerm 


bTerm := {|| 	"     Antes que sua atualiza็ใo inicie, voc๊ deve ler e aceitar os termos e as condi็๕es a seguir." 	+; 
				" Ap๓s aceitแ-los, voc๊ pode prosseguir com a atualiza็ใo."                                         	+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"ATENวรO: LEIA COM ATENวรO ANTES DE PROSSEGUIR COM A ATUALIZAวรO" 											+;
				PULALINHA 																											+;
				PULALINHA                 																						+;
				"ACORDO DE LICENวA DE SOFTWARE PARA USUมRIO FINAL ('ACORDO')" 												+;
				PULALINHA 																											+;
				PULALINHA                 																						+;
				"TERMOS E CONDIวีES"                                                                                 	+;
				PULALINHA                 																						+;
				"ADVERTสNCIAS LEGAIS: AO CLICAR NA OPวรO 'SIM, LI E ACEITO O TERMO ACIMA' NO FINAL DESTA JANELA,"    	+; 
				" VOCส INDICA QUE LEU E CONCORDOU COM TODOS OS TERMOS DESTE ACORDO E QUE CONSENTE EM SER REGIDO POR" 	+;
				" ESTE ACORDO E TORNAR-SE PARTE DELE.  A TOTVS ESTม DISPOSTA A DISPONIBILIZAR ESTE AJUSTE PARA VOCส" 	+;
				" APENAS SOB A CONDIวรO DE QUE VOCส CONCORDE COM TODOS OS TERMOS CONTIDOS NESTE ACORDO. SE VOCส NรO"	+;
				" CONCORDA COM TODOS OS TERMOS DESTE ACORDO, CLIQUE NO BOTรO 'CANCELAR' E NรO PROSSIGA COM O AJUSTE."	+;
				PULALINHA 																											+;
				"O ACORDO A SEGUIR ษ UM ACORDO LEGAL ENTRE VOCส (O USUมRIO FINAL, SEJA UM INDIVอDUO OU ENTIDADE),"	+;
				" E A TOTVS S/A. (PROPRIAMENTE DITA OU SUAS LICENCIADAS). " 												+;
				PULALINHA                 																						+;
				"ESTE SOFTWARE ษ LICENCIADO PELA TOTVS PARA VOCส, E QUALQUER RECEPTOR SUBSEQÜENTE DO SOFTWARE,"		+; 
				" SOMENTE PARA USO SEGUNDO OS TERMOS ESTABELECIDOS NESTE DOCUMENTO. " 									+;
				PULALINHA 																											+;
				PULALINHA                 																						+;
				"PREMISSAS DE UTILIZAวรO: Antes de executar esta rotina ้ obrigat๓ria a realiza็ใo de uma c๓pia de" 	+;
				" seguran็a geral do sistema Protheus (binแrio, RPO, dicionแrios SXs e banco de dados). Fa็a testes" 	+;
				" de performance e planeje-se antes de executar esta atualiza็ใo, pois ela requer acesso exclusivo" 	+;
				" เs tabelas do sistema (ou seja: nenhum usuแrio poderแ acessar o sistema) durante toda a sua"			+;
				" execu็ใo, que pode demorar vแrias horas para ser finalizada! Depois de iniciada esta rotina nใo"	+;
				" poderแ ser interrompida! Qualquer tipo de interrup็ใo (ex.:falta de energia, problemas de hardware"	+;
				" , problemas de rede, etc.) poderแ danificar todo o sistema! Neste caso deve-se realizar a"			+;
				" restaura็ใo da c๓pia de seguran็a feita imediatamente antes do inicio da atualiza็ใo antes de" 		+;
				" executแ-la novamente." 																						+;
				PULALINHA 																											+;
				PULALINHA                 																						+;
				"CONCESSรO DE LICENวA: A TOTVS lhe concede uma licen็a limitada, nใo-exclusiva e revogแvel para usar"	+;
				" a versใo de c๓digo executแvel da Atualiza็ใo do m๓dulo Ativo Fixo denominada UPDATF050,"	+;
				" eximindo-se de qualquer dado resultante da utiliza็ใo deste." 											+;
				PULALINHA 																											+;
				PULALINHA 																											+;  
				"DIREITOS AUTORAIS: O Software ้ propriedade da TOTVS e estแ protegido por leis de direitos autorais"	+;
				" do Brasil e disposi็๕es de tratados internacionais.  Voc๊ reconhece que nใo lhe serแ transferido"	+;
				" qualquer direito a qualquer propriedade intelectual do Software. " 										+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"LIMITAวีES: Exceto se explicitamente disposto em contrแrio neste Acordo, voc๊ nใo pode:"				+;
				PULALINHA 																											+;
				"a) modificar o Software ou criar trabalhos derivados do mesmo; "											+;
				PULALINHA 																											+;
				"b) descompilar, desmontar, fazer engenharia reversa, ou de outras maneiras tentar alterar o c๓digo"	+;
				"-fonte do Software;"																							+;
				PULALINHA 																											+;
				"c) copiar (exceto para fazer uma c๓pia de backup), redistribuir, impedir, vender, alugar, arrendar"	+;
				", sublicenciar, atribuir ou de outras maneiras transferir seus direitos ao Software; ou " 			+;
				PULALINHA 																											+;				
				"d) remover ou alterar qualquer marca registrada, logotipo, registro ou outras advert๊ncias"			+;
				" proprietแrias no Software.  Voc๊ pode transferir todos os seus direitos ao Software regidos por"	+;
				" este Acordo para outra pessoa transferindo-lhe, permanentemente, o computador pessoal no qual o"	+;
				" Software estแ instalado, contanto que voc๊ nใo retenha nenhuma c๓pia do Software e que o receptor"	+;
				" concorde com todos os termos deste Acordo. " 																+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"ATIVIDADES DE ALTO RISCO: O Software nใo ้ tolerante a falhas e nใo foi projetado, fabricado ou"		+;
				" desenvolvido para uso em ambientes perigosos que requerem desempenho เ prova de falhas, como na"	+;
				" opera็ใo de instala็๕es nucleares, navega็ใo de aeronaves ou sistemas de comunica็ใo, controle de"	+;
				" trแfego a้reo, dispositivos m้dicos implantados em seres humanos, mแquinas externas de suporte เ"	+;
				" vida humana, dispositivos de controle de explosivos, submarinos, sistemas de armas ou controle de"	+;
				" opera็ใo de veํculos motorizados nos quais a falha do Software poderia levar diretamente เ morte,"	+;
				" danos pessoais ou danos fํsicos ou ambientais graves ('Atividades de Alto Risco'). Voc๊ concorda"	+;
				" em nใo usar o Software em Atividades de Alto Risco. " 													+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"RENฺNCIA ภS GARANTIAS: A TOTVS nใo garante que o Software satisfarแ suas exig๊ncias, que a opera็ใo"	+;
				" do mesmo serแ ininterrupta ou livre de erros, ou que todos os erros de Software serใo corrigidos."	+;
				" Todo o risco no que se refere เ qualidade e ao desempenho do Software decorre por sua conta."		+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"O SOFTWARE ษ FORNECIDO 'COMO ESTม' E SEM GARANTIAS DE QUALQUER TIPO, EXPRESSAS OU IMPLอCITAS,"		+;
				" INCLUINDO, MAS NรO SE LIMITANDO A, GARANTIAS DE TอTULOS, NรO-VIOLAวรO, COMERCIALIZAวรO E ADEQUAวรO"	+;
				" PARA UMA FINALIDADE EM PARTICULAR.  NENHUMA INFORMAวรO OU CONSELHO VERBAL OU POR ESCRITO,"			+;
				" FORNECIDOS PELA TOTVS, SEUS FUNCIONมRIOS, DISTRIBUIDORES, REVENDEDORES OU AGENTES AUMENTARรO O"		+;
				" ESCOPO DAS GARANTIAS ACIMA OU CRIARรO QUALQUER GARANTIA NOVA." 											+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"LIMITAวรO DE RESPONSABILIDADE: MESMO QUE QUALQUER SOLUวรO FORNECIDA NA GARANTIA FALHE EM SEU"			+;
				" PROPำSITO ESSENCIAL, EM NENHUM EVENTO A TOTVS TERม OBRIGAวีES POR QUALQUER DANO ESPECIAL,"			+;
				" CONSEQÜENTE, INDIRETO OU SEMELHANTE, INCLUINDO PERDA DE LUCROS OU DADOS, DERIVADOS DO USO OU"		+;
				" INABILIDADE DE USAR O SOFTWARE, OU QUAISQUER DADOS FORNECIDOS, MESMO QUE A TOTVS OU OUTRA PARTE"	+;
				" TENHA SIDO AVISADA DA POSSIBILIDADE DE TAL DANO, OU EM QUALQUER REIVINDICAวรO DE QUALQUER OUTRA"	+;
				" PARTE." 																											+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"ALGUMAS JURISDIวีES NรO PERMITEM A LIMITAวรO OU EXCLUSรO DE RESPONSABILIDADE POR DANOS INCIDENTAIS"	+;
				" OU CONSEQÜENTES; PORTANTO, A LIMITAวรO OU EXCLUSรO ACIMA PODE NรO SE APLICAR AO SEU CASO." 			+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"TERMO: Este Acordo ้ vแlido at้ ser terminado.  Este Acordo terminarแ, e a licen็a concedida a voc๊"	+;
				" por este Acordo serแ revogada, imediatamente, sem qualquer advert๊ncia da TOTVS, se voc๊ nใo"		+;
				" obedecer a qualquer disposi็ใo deste Acordo. Ao t้rmino do mesmo, voc๊ deverแ destruir o Software."	+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"ACORDO INTEGRAL: Este Acordo constitui o acordo integral entre voc๊ e a TOTVS, no que se refere ao"	+;
				" Software licenciado, e substitui todas as comunica็๕es, as representa็๕es, as compreens๕es e os"	+;
				" acordos anteriores, verbais ou por escrito, entre voc๊ e a TOTVS relativos a este Software.  Este"	+;
				" Acordo nใo pode ser modificado ou renunciado, exceto por escrito e assinado por uma autoridade ou"	+;
				" outro representante autorizado de cada parte." 															+;
				PULALINHA 																											+;
				PULALINHA 																											+;
				"Se qualquer disposi็ใo for considerada invแlida, todas as outras permanecerใo vแlidas, a menos que"	+;
				" impe็a o prop๓sito de nosso Acordo.  A falha de qualquer parte em refor็ar qualquer direito"			+;
				" concedido neste documento, ou em entrar em a็ใo contra a outra parte no caso de qualquer viola็ใo,"	+;
				" nใo serแ considerada uma desist๊ncia เ subseqüente execu็ใo dos direitos ou เ subseqüente a็ใo no"	+;
				" caso de futuras viola็๕es." }

oPanel   	:= oWizard:oMPanel[oWizard:nPanel]

oScrolTerm	:= TScrollBox():New(oPanel,005,005,125,291,.T.,.T.,.T.)
oCheckTerm	:= TCheckBox():New( 135,008,"Sim, li e aceito os termos acima.",bSETGET(lChkTerm)		,oPanel,150,009,,,,,,,,.T.,,,) //"Sim, li e aceito os termos acima."

 // Cria objetos para teste do Scroll   
oFont 	:= TFont():New('Courier new',,-12,.T.)   
oSay1	:= TSay():New(008,008,bTerm, oScrolTerm,,oFont,,,,.T.,CLR_BLUE,CLR_WHITE,270,900) 

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณUpdAtfTerm  บAutor  ณFelipe Cunha       บ Data ณ  01/04/14  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Termo de Aceite											  		 บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function UpdAtfP4()
Local oPanel		:= Nil
Local oCheckTerm
Local oScrolTerm
Local bTerm 


bTerm := {|| 	"Esta rotina irแ ajustar os Movimentos do Ativo(SN4) a partir dos parametros      	" +;
				"informado e os valores acumulados de deprecia็ใo na tabela Tipos de Ativos(SN3) 	" +;
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
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณUpdAtfTerm  บAutor  ณFelipe Cunha       บ Data ณ  01/04/14  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Termo de Aceite											  		 บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function UpdAtfP3()
Local oPanel		:= Nil
Local dDataIni		:= FirstDay(dDataBase)
Local dDataFin		:= LastDay(dDataBase)

aPerg := {}
aResp := {}

oPanel   	:= oWizard:oMPanel[oWizard:nPanel]
aAdd(aPerg,{1,"Data De:"				,dDataIni,""	,"","",,50,.T.}) 				//"Periodo Inicial da Escritura็ใo: "
aAdd(aPerg,{1,"Data Ate"				,dDataFin,""	,"","",,50,.T.}) 				//"Periodo Final da Escritura็ใo: "
aAdd(aPerg,{3,"Seleciona Filiais"	, 1	, {"Sim", "Nใo"}	, 100,"", .T. })		//"Tipos de saldo"###"1-Normais"###"2-Conciliados"###"3-Nใo conciliados"
aResp := {dDataIni,dDataFin, 1}
ParamBox(aPerg,"",aResp,,,,,,oPanel) 

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณUpdAtfPros  บAutor  ณFelipe Cunha       บ Data ณ  01/04/14  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Termo de Aceite											  		 บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function UpdAtfPros()


If aResp[3] == 1
	aSelFil := AdmGetFil()
Else
	aSelFil := {cFilAnt}
EndIf

Return .T.

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณUpdAtfTOk  บAutor  ณFelipe Cunha       บ Data ณ  01/04/14  บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Termo de Aceite											  		 บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
Static Function UpdAtfTOk()

Local dDataIni 	:= aResp[1] 				//Movimentos SN4 - Data De
Local dDataFim 	:= aResp[2] 				//Movimentos SN4  - Data Ate
Local cAliasQry	:= ''						//Movimentos SN4  - Qry Movimentos
Local cQuery 		:= ''						//Movimentos SN4  - Qry Movimentos
Local cOcorr		:= ''						//Movimentos SN4  - Codigo Ocorrencia
Local aValDepr 	:= AtfMultMoe(,,{|x| 0})	//Movimentos SN4  - Valor de Deprecia็ใo
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
		
		//Taxa de Deprecia็ใo
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
					//Atualiza Valor de Deprecia็ใo Acumulada
					SN3->N3_VRDACM1 := (cAliasQrySN3)->VALOR1
					SN3->N3_VRDACM2 := (cAliasQrySN3)->VALOR2
					SN3->N3_VRDACM3 := (cAliasQrySN3)->VALOR3
					SN3->N3_VRDACM4 := (cAliasQrySN3)->VALOR4
					SN3->N3_VRDACM5 := (cAliasQrySN3)->VALOR5
					
					/*
					//Atualiza Valor da Ultima Deprecia็ใo
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
	
	
	
    //Atualiza Valor Acumulado ap๓s a ultima virada Anual
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
	
			//Atualiza Valor Acumulado ap๓s a ultima virada Anual
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