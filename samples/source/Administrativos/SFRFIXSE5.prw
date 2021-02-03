#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWIZARD.CH"

STATIC __lBlind		:= IsBlind()

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �FINFIXSE5  �Autor  �TOTVS SA           � Data �  10/01/12   ���
�������������������������������������������������������������������������͹��
���Desc.     � Funcao principal para altera��o de campos na base de dados ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � AP                                                        ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
User Function SFRFIXSE5()
Private oWizard
Private aRet	:= {MsDate(),{"Sim","N�o"},Space(Len(xFilial())),Space(Len(xFilial()))}
Private lOk		:= .T.

oWizard := APWizard():New( "Assistente para Ajuste de base." ,"Aten��o!" ,;
"",;
"Este assistente tem como finalidade acertar a tabela SE5 com rela��o aos registros da tabela SFR quando foi efetuado o c�lculo de diferen�a de cambio, permitindo a anula��o da dif. de cambio.";
+CHR(10)+CHR(13)+"- Somente rodar este ajuste em modo exclusivo!";
+CHR(10)+CHR(13)+"- Realizar backup do banco de dados antes da atualiza��o.";
+CHR(10)+CHR(13)+"- Rodar a atualiza��o primeiramente em base de homologa��o.";
+CHR(10)+CHR(13)+"- Esta rotina est� preparada para ser rodada apenas 1 vez!";
+CHR(10)+CHR(13)+"- Caso seja necess�rio complementar a regra de processamento, a altera��o deste EXEMPLO fica a crit�rio do cliente!",;
{|| .T.}, {|| FinExecFix()},,,,,) 
			

ACTIVATE WIZARD oWizard CENTERED  WHEN {||.T.}

Return

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �FinExecFix�Autor  �TOTVS SA            � Data �  10/01/12   ���
�������������������������������������������������������������������������͹��
���Desc.     � Funcao que executa o acerto da tabela SE5 com rela��o aos  ���
���          � registros contidos na tabela SFR.                          ���
�������������������������������������������������������������������������͹��
���Uso       � AP                                                        ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function FinExecFix()
Local aArea := GetArea()
Local nTamCod   := TamSX3("E1_CLIENTE")[1]
Local nTamLoja  := TamSX3("E1_LOJA")[1]
Local nTamPrfx  := TamSX3("E1_PREFIXO")[1]
Local nTamNum   := TamSX3("E1_NUM")[1]
Local nTamParc  := TamSX3("E1_PARCELA")[1]
Local nTamTipo	 := TamSX3("E1_TIPO")[1]  
Local lOk		 := MsgYesNo("A base de dados ser� alterada ap�s esta confirma��o! Tem certeza que deseja atualiz�-la?")
Local aRecLog	 := {}   
Local nX			 := 0 
Local cPath		 := ""        

If lOk
	DbSelectArea("SFR")
	DbGoTop()
	
	While !SFR->(Eof())
	
		DbSelectArea("SE5")
		DbSetOrder(7)//E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA
		If !DbSeek(xFilial("SE5") + SFR->(SubStr(FR_CHAVDE,1+nTamCod+nTamLoja,nTamPrfx)) +;
						SFR->(SubStr(FR_CHAVDE,1+nTamCod+nTamLoja+nTamPrfx,nTamNum)) +;
						SFR->(SubStr(FR_CHAVDE,1+nTamCod+nTamLoja+nTamPrfx+nTamNum,nTamParc)) +;
						SFR->(SubStr(FR_CHAVDE,1+nTamCod+nTamLoja+nTamPrfx+nTamNum+nTamParc,nTamTipo)) +;
						SFR->(SubStr(FR_CHAVDE,1,nTamCod)) +;
						SFR->(SubStr(FR_CHAVDE,1+nTamCod,nTamLoja)))
	
			DbSelectArea("SE1")
			DbSetOrder(2)
			If DbSeek(xFilial("SE1") + SFR->(SubStr(FR_CHAVDE,1,nTamCod)) +;
							SFR->(SubStr(FR_CHAVDE,1+nTamCod,nTamLoja)) +;
							SFR->(SubStr(FR_CHAVDE,1+nTamCod+nTamLoja,nTamPrfx)) +;
							SFR->(SubStr(FR_CHAVDE,1+nTamCod+nTamLoja+nTamPrfx,nTamNum)) +;
							SFR->(SubStr(FR_CHAVDE,1+nTamCod+nTamLoja+nTamPrfx+nTamNum,nTamParc)) +;
							SFR->(SubStr(FR_CHAVDE,1+nTamCod+nTamLoja+nTamPrfx+nTamNum+nTamParc,nTamTipo)))
	
				Fa070GrvSe5("","","",SE1->E1_BAIXA,SFR->FR_VALOR,.F.,.F.,"BA","De baja parcial ",;
								"        ","DIF",SFR->FR_VALOR,"01",.F.,"1",SE1->E1_BAIXA,"",;
								"",1,5,0,0,0,0,{})
								
				aAdd(aRecLog,xFilial("SE5") + SFR->(SubStr(FR_CHAVDE,1+nTamCod+nTamLoja,nTamPrfx)) +;
						SFR->(SubStr(FR_CHAVDE,1+nTamCod+nTamLoja+nTamPrfx,nTamNum)) +;
						SFR->(SubStr(FR_CHAVDE,1+nTamCod+nTamLoja+nTamPrfx+nTamNum,nTamParc)) +;
						SFR->(SubStr(FR_CHAVDE,1+nTamCod+nTamLoja+nTamPrfx+nTamNum+nTamParc,nTamTipo)) +;
						SFR->(SubStr(FR_CHAVDE,1,nTamCod)) +;
						SFR->(SubStr(FR_CHAVDE,1+nTamCod,nTamLoja)))
			EndIf
		EndIf     
	
		SFR->(DbSkip())
	
	EndDo  
EndIf

// ********* GERA��O DO LOG ********* //
If Len(aRecLog) > 0
	AutoGrLog("LOG de altera��es na tabela SE5 - " +DtoC(MsDate())+ ' ' + Time() )
	AutoGrLog("Cada linha apresentada abaixo � referente")
	AutoGrLog("a um registro criado na tabela SE5 com base na tabela SFR")
	DbSelectArea("SE5")
	DbSetOrder(7)//E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA
	For nX := 1 To Len(aRecLog)
		AutoGrLog("-------------------------------------------------------")
		AutoGrLog("SFR: "	+ aRecLog[nX])
		SE5->(DbSeek(aRecLog[nX]))
		AutoGrLog("SE5: "	+ SE5->(E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA))
		AutoGrLog("Recno SE5: "	+ STR(SE5->(Recno())))
	Next nX

	cFileLog := NomeAutoLog()

	If cFileLog <> ""
		MostraErro(cPath,cFileLog)
	Endif
EndIf

RestArea(aArea)
Return lOk