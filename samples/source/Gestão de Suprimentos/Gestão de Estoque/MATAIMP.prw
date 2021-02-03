#INCLUDE "MATAIMP.CH"
#INCLUDE "PROTHEUS.CH"
/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    � MATAIMP  � Autor �Rodrigo de A. Sartorio � Data � 30.03.01 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Programa para importar dados e permitir implantacao do     ���
���          � sistema sem inconsistencia de dados                        ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � Generico                                                   ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
User Function MATAIMP(lBat,nOpcao)
//��������������������������������������������������������������Ŀ
//� Define Variaveis                                             �
//����������������������������������������������������������������
LOCAL nOpca := 0, oDlg
LOCAL cCadastro := OemtoAnsi(STR0001)  	//"Importa Dados"
LOCAL aSays:={}, aButtons := {}
LOCAL cMens:=""

lBat:=If(lBat == NIL,.F.,lBat)
nOpcao:=If(ValType(nOpcao) # "N",0,nOpcao)

TCInternal(5,"*OFF")   // Desliga Refresh no Lock do Top
If !lBat
	cMens := OemToAnsi(STR0025)+chr(13) //"Esta rotina ser� executada em modo"
	cMens += OemToAnsi(STR0026)+chr(13) //"compartilhado , conforme necessidade"
	cMens += OemToAnsi(STR0027)+chr(13) //"do sistema. Continua com o processo ?"
	IF !MsgYesNo(cMens,OemToAnsi(STR0028)) //"ATENCAO"
		Return
	EndIf
	AADD(aSays,OemToAnsi(STR0002)) //"Atraves deste programa o sistema ira importar dados evitando "
	AADD(aSays,OemToAnsi(STR0003)) //"grande volume de digitacao,auxiliando a implantacao de dados "
	AADD(aSays,OemToAnsi(STR0004)) //"no sistema de maneira consistente e rapida."
	AADD(aButtons,{1,.T.,{|o| nOpca:= 1,(nOpca:= 1,nOpcao:=1,o:oWnd:End()) } } )
	AADD(aButtons,{2,.T.,{|o| o:oWnd:End()}})
	FormBatch( cCadastro, aSays, aButtons,,200,405 )
Else
	nOpca:=1
EndIf
If nOpcA == 1
	Processa({|lEnd| MatImpProc(nOpcao),STR0005})  //"Importacao dos saldos em estoque"
Endif
Return

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    �MatImpProc� Autor �Rodrigo de A. Sartorio � Data �30/03/01  ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Processamento                                              ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � MATAIMP                                                    ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function MatImpProc(nOpcao)
LOCAL aDados   :={{}}
LOCAL aLogs    :={}
LOCAL aCampos  :={}
LOCAL lRet     :=.F.
LOCAL nx,nz,ny
LOCAL nLinhas  :=0
LOCAL cNumLote :=""
LOCAL dDataFec :=GETMV("MV_ULMES")
LOCAL cSeek    := ""

//��������������������������������������������������������������Ŀ
//� Carrega os dados da importacao atraves de execblock          �
//����������������������������������������������������������������
If ExistBlock("MATIMP")
	aDados:=Execblock("MATIMP",.F.,.F.,nOpcao)
	lRet:=ValType(aDados) == "A"
EndIf
//��������������������������������������������������������������Ŀ
//� Opcao 1 - Importacao dos saldos em estoque                   �
//����������������������������������������������������������������
If lRet
	If nOpcao == 1
		If !(MA280FLock("SB1") .And. MA280FLock("SB2") .And. MA280FLock("SB8") .And. MA280Flock("SB9") .And.;
				MA280FLock("SBE") .And. MA280FLock("SBF") .And. MA280FLock("SBJ") .And.;
				MA280FLock("SBK"))
			//��������������������������������������������������������������Ŀ
			//� Fecha todos os arquivos e reabre-os de forma compartilhada   �
			//����������������������������������������������������������������
			dbCloseAll()
			OpenFile(SubStr(cNumEmp,1,2))
			Return(NIL)
		EndIf
		OpenIndx("SB1")
		OpenIndx("SB2")
		OpenIndx("SB8")
		OpenIndx("SB9")
		OpenIndx("SBE")
		OpenIndx("SBF")
		OpenIndx("SBJ")
		OpenIndx("SBK")
		//��������������������������������������������������������������Ŀ
		//� Estrutura do array para importacao dos dados                 �
		//� COLUNA 01- Codigo do produto                                 �
		//� COLUNA 02- Almoxarifado                                      �
		//� COLUNA 03- Lote                                              �	
		//� COLUNA 04- Data de validade do Lote                          �	
		//� COLUNA 05- Localizacao                                       �		
		//� COLUNA 06- Numero de Serie                                   �	
		//� COLUNA 07- Quantidade                                        �	
		//� COLUNA 08- Quantidade na segunda UM                          �	
		//� COLUNA 09- Valor do movimento Moeda 1                        �	
		//� COLUNA 10- Valor do movimento Moeda 2                        �	
		//� COLUNA 11- Valor do movimento Moeda 3                        �	
		//� COLUNA 12- Valor do movimento Moeda 4                        �	
		//� COLUNA 13- Valor do movimento Moeda 5                        �	
		//����������������������������������������������������������������
		//��������������������������������������������������������������Ŀ
		//� Monta array para validacao dos dados                         �
		//����������������������������������������������������������������
		AADD(aCampos,CriaVar("D3_COD"))
		AADD(aCampos,CriaVar("D3_LOCAL"))
		AADD(aCampos,CriaVar("D3_LOTECTL"))
		AADD(aCampos,CriaVar("D3_DTVALID"))
		AADD(aCampos,CriaVar("D3_LOCALIZ"))
		AADD(aCampos,CriaVar("D3_NUMSERI"))
		AADD(aCampos,CriaVar("D3_QUANT"))
		AADD(aCampos,CriaVar("D3_QTSEGUM"))
		AADD(aCampos,CriaVar("B9_VINI1"))
		AADD(aCampos,CriaVar("B9_VINI2"))
		AADD(aCampos,CriaVar("B9_VINI3"))
		AADD(aCampos,CriaVar("B9_VINI4"))
		AADD(aCampos,CriaVar("B9_VINI5"))
		//��������������������������������������������������������������Ŀ
		//� Sorteia dados de acordo com utilizacao na rotina             �
		//����������������������������������������������������������������
		For nx:=1 to Len(aDados)
			ASORT(aDados[nx],,,{ |x,y| x[1]+x[2]+x[3]+x[5]+x[6] < y[1]+y[2]+y[3]+y[5]+y[6]})
		Next nx	

		dbSelectArea("SB1")
		dbSetOrder(1)

		dbSelectArea("SB2")
		dbSetOrder(1)

		dbSelectArea("SB9")
		dbSetOrder(1)

		dbSelectArea("SB8")
		dbSetOrder(1)

		dbSelectArea("SBE")
		dbSetOrder(1)

		dbSelectArea("SBF")
		dbSetOrder(2)

		dbSelectArea("SBJ")
		dbSetOrder(1)

		dbSelectArea("SBK")
		dbSetOrder(1)
		
		//��������������������������������������������������������������Ŀ
		//� Tipo de logs existentes                                      �
		//����������������������������������������������������������������
		// 01 TIPO DE DADO INVALIDO
		// 02 SALDO JA IMPLANTADO NO SISTEMA
		// 03 QTD INCORRETA
		// 04 PRODUTO COM LOTE SEM RASTRO PREENCHIDO
		// 05 PRODUTO COM LOTE SEM VALIDADE PREENCHIDA
		// 06 PRODUTO SEM LOTE COM RASTRO PREENCHIDO
		// 07 PRODUTO COM LOCALIZACAO SEM ENDERECEO/NS PREENCHIDO
		// 08 PRODUTO COM LOCALIZACAO COM ENDERECO NAO CADASTRADO
		// 09 PRODUTO COM LOCALIZACAO COM NS COM QTD INVALIDA
		// 10 PRODUTO SEM LOCALIZACAO COM ENDERECEO/NS PREENCHIDO
		// 11 PRODUTO NAO ENCONTRADO
				
		//��������������������������������������������������������������Ŀ
		//� Valida os dados passados atraves do array                    �
		//����������������������������������������������������������������
		For nx:=1 to Len(aDados)
			ProcRegua(Len(aDados[nx]))
			For nz:=1 to Len(aDados[nx])
				IncProc()
				For ny:=1 to Len(aDados[nx,nz])
					If ValType(aDados[nx,nz,ny]) # ValType(aCampos[ny])
						//���������������������������������������������������Ŀ
						//� Adiciona registro em array para Log               �
						//�����������������������������������������������������
						MatADDLog(aLogs,STR0006+" -> "+Str(ny),1,NIL,NIL,nx,nz) // "A coluna do array apresenta erro do tipo de dado diferente do necessario "
					EndIf			
				Next ny
			Next nz
		Next nx		

		For nx:=1 to Len(aDados)
			For nz:=1 to Len(aDados[nx])
				nLinhas++
				//��������������������������������������������������������������Ŀ
				//� Verifica se o produto existe no SB1 - Cadastro de Produtos   �
				//����������������������������������������������������������������
				If SB1->(dbSeek(xFilial("SB1")+aDados[nx,nz,1]))
					//��������������������������������������������������������������Ŀ
					//� Verifica se o saldo realmente nao foi implantado nos arquivos�
					//� de saldos                                                    �
					//����������������������������������������������������������������
					If SB2->(dbSeek(xFilial("SB2")+aDados[nx,nz,1]))
						//���������������������������������������������������Ŀ
						//� Adiciona registro em array para Log               �
						//�����������������������������������������������������
						MatADDLog(aLogs,STR0007+"SB2/"+aDados[nx,nz,1],2,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "Saldo ja implantado no sistema, verifique arquivo/produto "
					EndIf
					If SB8->(dbSeek(xFilial("SB8")+aDados[nx,nz,1]))
						//���������������������������������������������������Ŀ
						//� Adiciona registro em array para Log               �
						//�����������������������������������������������������
						MatADDLog(aLogs,STR0007+"SB8/"+aDados[nx,nz,1],2,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "Saldo ja implantado no sistema, verifique arquivo/produto "
					EndIf
					If SB9->(dbSeek(xFilial("SB9")+aDados[nx,nz,1]))
						//���������������������������������������������������Ŀ
						//� Adiciona registro em array para Log               �
						//�����������������������������������������������������
						MatADDLog(aLogs,STR0007+"SB9/"+aDados[nx,nz,1],2,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "Saldo ja implantado no sistema, verifique arquivo/produto "
					EndIf
					If SBF->(dbSeek(xFilial("SBF")+aDados[nx,nz,1]))
						//���������������������������������������������������Ŀ
						//� Adiciona registro em array para Log               �
						//�����������������������������������������������������
						MatADDLog(aLogs,STR0007+"SBF/"+aDados[nx,nz,1],2,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "Saldo ja implantado no sistema, verifique arquivo/produto "
					EndIf
					//��������������������������������������������������������������Ŀ
					//� O produto tem de ter alguma quantidade no movimento          �
					//����������������������������������������������������������������
					If Empty(aDados[nx,nz,7])
						//���������������������������������������������������Ŀ
						//� Adiciona registro em array para Log               �
						//�����������������������������������������������������
						MatADDLog(aLogs,STR0008+" -> "+aDados[nx,nz,1],3,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "O item do array tem de ter qtd maior que zero - Erro no produto"
					EndIf				
					//��������������������������������������������������������������Ŀ
					//� Caso o produto utilize rastreabilidade deve ter o numero do  �
					//� lote e a data de validade preenchidos                        �
					//����������������������������������������������������������������
					If Rastro(aDados[nx,nz,1])
						If Empty(aDados[nx,nz,3])
							//���������������������������������������������������Ŀ
							//� Adiciona registro em array para Log               �
							//�����������������������������������������������������
							MatADDLog(aLogs,STR0009+" -> "+aDados[nx,nz,1],4,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "Produto utiliza rastreabilidade e nao tem o lote preenchido "
						EndIf
						If Empty(aDados[nx,nz,4])
							//���������������������������������������������������Ŀ
							//� Adiciona registro em array para Log               �
							//�����������������������������������������������������
							MatADDLog(aLogs,STR0010+" -> "+aDados[nx,nz,1],5,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "Produto utiliza rastreabilidade e nao tem a data de validade do lote preenchida "
						EndIf
					ElseIf !Rastro(aDados[nx,nz,1]) .And. !Empty(aDados[nx,nz,3])
						//���������������������������������������������������Ŀ
						//� Adiciona registro em array para Log               �
						//�����������������������������������������������������
						MatADDLog(aLogs,STR0011+" -> "+aDados[nx,nz,1],6,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "Produto nao utiliza rastreabilidade e tem o lote preenchido "
					EndIf
					//��������������������������������������������������������������Ŀ
					//� Caso o produto utilize localizacao fisica deve ter a localiza�
					//� cao ou o numero de serie preenchidos                         �
					//����������������������������������������������������������������
					If Localiza(aDados[nx,nz,1])
						If Empty(aDados[nx,nz,5]+aDados[nx,nz,6])
							//���������������������������������������������������Ŀ
							//� Adiciona registro em array para Log               �
							//�����������������������������������������������������
							MatADDLog(aLogs,STR0012+" -> "+aDados[nx,nz,1],7,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "Produto utiliza localizacao fisica e nao tem localizacao e/ou  numero de serie preenchida(o) "
						EndIf
						//��������������������������������������������������������������Ŀ
						//� Caso o produto utilize localizacao fisica deve ter a localiza�
						//� cao existente no SBE                                         �
						//����������������������������������������������������������������
						If !Empty(aDados[nx,nz,5])
							If !SBE->(dbSeek(xFilial("SBE")+aDados[nx,nz,2]+aDados[nx,nz,5]))
								//���������������������������������������������������Ŀ
								//� Adiciona registro em array para Log               �
								//�����������������������������������������������������
								MatADDLog(aLogs,STR0013+" -> "+aDados[nx,nz,5],8,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "A localizacao nao esta cadastrado no cadastro de localizacoes "
							EndIf
						EndIf
						//��������������������������������������������������������������Ŀ
						//� Se o numero de serie estiver preenchido a qtd deve ser igual �
						//� a 1                                                          �
						//����������������������������������������������������������������
						If	!MtAvlNSer(aDados[nx,nz,1],aDados[nx,nz,6],aDados[nx,nz,7],aDados[nx,nz,8],.F.)
							//���������������������������������������������������Ŀ
							//� Adiciona registro em array para Log               �
							//�����������������������������������������������������
							MatADDLog(aLogs,STR0014+" -> "+aDados[nx,nz,6],9,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "O numero de serie nao apresenta qtd igual a 1 como obrigatorio "
						EndIf
					Else
						If !Empty(aDados[nx,nz,5]+aDados[nx,nz,6])
							//���������������������������������������������������Ŀ
							//� Adiciona registro em array para Log               �
							//�����������������������������������������������������
							MatADDLog(aLogs,STR0015+" -> "+aDados[nx,nz,1],10,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "Produto nao utiliza localizacao fisica e tem localizacao e/ou  numero de serie preenchido "
						EndIf
					EndIf
				Else
					//���������������������������������������������������Ŀ
					//� Adiciona registro em array para Log               �
					//�����������������������������������������������������
					MatADDLog(aLogs,STR0016+" -> "+aDados[nx,nz,1],11,aDados[nx,nz,1],aDados[nx,nz,2],nx,nz) // "O produto nao esta cadastrado no arquivo de produtos "
				EndIf
			Next nz
		Next nx	

		//��������������������������������������������������������������Ŀ
		//� Executa a gravacao dos dados                                 �
		//����������������������������������������������������������������
		ProcRegua(nLinhas)
		For nx:=1 to Len(aDados)
			For nz:=1 to Len(aDados[nx])
				IncProc()				
				//��������������������������������������������������������������Ŀ
				//� Procura log para esse registro                               �
				//����������������������������������������������������������������
				ny:=aScan(aLogs,{|x| x[5] == nx .And. x[6] == nz})		
				//��������������������������������������������������������������Ŀ
				//� Procura log para esse produto / armazem                      �
				//����������������������������������������������������������������
				If ny <= 0
					ny:=aScan(aLogs,{|x| x[3] == aDados[nx,nz,1] .And. x[4] == aDados[nx,nz,2]})						
				EndIf
				//��������������������������������������������������������������Ŀ
				//� Se nao apresentou inconsistencia grava item                  �
				//����������������������������������������������������������������
				If ny <= 0
					//��������������������������������������������������������������Ŀ
					//� Criacao dos saldos iniciais - Estes saldos devem ser criados �
					//� com a data em branco para que o sistema assuma como saldo de �
					//� implantacao                                                  �
					//����������������������������������������������������������������
					//��������������������������������������������������������������Ŀ
					//� Grava o saldo inicial no SB9                                 �
					//����������������������������������������������������������������
					dbSelectArea("SB9")
					If !dbSeek(xFilial()+aDados[nx,nz,1]+aDados[nx,nz,2])
						RecLock("SB9",.T.)
						Replace B9_FILIAL With xFilial()
						Replace B9_COD With aDados[nx,nz,1]
						Replace B9_LOCAL With aDados[nx,nz,2]
						Replace B9_DATA With ddataFec
					Else
						RecLock("SB9",.F.)
					EndIf
					Replace	B9_QINI With B9_QINI + aDados[nx,nz,7]
					Replace  B9_QISEGUM With B9_QISEGUM + ConvUm(B9_COD,aDados[nx,nz,7],aDados[nx,nz,8],2)
					Replace	B9_VINI1 With B9_VINI1 + aDados[nx,nz,9]
					Replace	B9_VINI2 With B9_VINI2 + aDados[nx,nz,10]
					Replace  B9_VINI3 With B9_VINI3 + aDados[nx,nz,11]
					Replace	B9_VINI4 With B9_VINI4 + aDados[nx,nz,12]
					Replace  B9_VINI5 With B9_VINI5 + aDados[nx,nz,13]
	
					MsUnlock()
					//��������������������������������������������������������������Ŀ
					//� Grava o saldo inicial no SBJ                                 �
					//����������������������������������������������������������������
					cNumLote:=CriaVar("B8_NUMLOTE")
					If Rastro(aDados[nx,nz,1])
						dbSelectArea('SBJ')
						If !dbSeek(xFilial('SBJ')+aDados[nx,nz,1]+aDados[nx,nz,2]+aDados[nx,nz,3])
							cNumLote:=NextLote(aDados[nx,nz,1],"S")
							RecLock('SBJ',.T.)
							Replace BJ_FILIAL  With xFilial('SBJ')
							Replace BJ_COD     With aDados[nx,nz,1]
							Replace BJ_LOCAL   With aDados[nx,nz,2]
							Replace BJ_LOTECTL With aDados[nx,nz,3]
							Replace BJ_DTVALID With aDados[nx,nz,4]
							Replace BJ_NUMLOTE With cNumLote
							Replace BJ_DATA    With ddataFec
						Else
							RecLock('SBJ',.F.)
						EndIf
						Replace BJ_QINI    With BJ_QINI + aDados[nx,nz,7]
						Replace BJ_QISEGUM With BJ_QISEGUM + ConvUm(BJ_COD,aDados[nx,nz,7],aDados[nx,nz,8],2)
						MsUnlock()			
						If Rastro(aDados[nx,nz,1],"L")
							cNumLote:=Space(Len(BJ_NUMLOTE))
						EndIf
					EndIf
					//��������������������������������������������������������������Ŀ
					//� Grava o saldo inicial no SBK                                 �
					//����������������������������������������������������������������
					If Localiza(aDados[nx,nz,1])
						dbSelectArea('SBK')
						If !dbSeek(xFilial('SBK')+aDados[nx,nz,1]+aDados[nx,nz,2]+aDados[nx,nz,3]+cNumLote+aDados[nx,nz,5]+aDados[nx,nz,6])
							RecLock('SBK',.T.)
							Replace BK_FILIAL  With xFilial('SBK')
							Replace BK_COD     With aDados[nx,nz,1]
							Replace BK_LOCAL   With aDados[nx,nz,2]
							Replace BK_LOTECTL With aDados[nx,nz,3]
							Replace BK_NUMLOTE With cNumLote
							Replace BK_LOCALIZ With aDados[nx,nz,5]
							Replace BK_NUMSERI With aDados[nx,nz,6]
							Replace BK_DATA    With ddataFec
						Else
							RecLock('SBK',.F.)
						EndIf
						Replace BK_QINI    With BK_QINI + aDados[nx,nz,7]
						Replace BK_QISEGUM With BK_QISEGUM + ConvUm(BK_COD,aDados[nx,nz,7],aDados[nx,nz,8],2)
						MsUnlock()			
					EndIf
				EndIf
			Next nz
		Next nx	
		//��������������������������������������������������������������Ŀ
		//� Varrendo o SB9 cria o registro no SB2                        �
		//����������������������������������������������������������������
		dbSelectArea("SB9")
		dbSeek(cSeek:=xFilial())
		While !SB9->(Eof()) .And. SB9->B9_FILIAL == cSeek
			A220ATUSB2(nil,nil,.F.,.F.)
			SB9->(dbSkip())
		EndDo			
		//��������������������������������������������������������������Ŀ
		//� Varrendo o SBJ cria o registro no SB8                        �
		//����������������������������������������������������������������
		dbSelectArea("SBJ")
		dbSeek(cSeek:=xFilial())
		While !SBJ->(Eof()) .And. SBJ->BJ_FILIAL == cSeek
			dbSelectArea("SB8")
			dbSetOrder(3) // B8_FILIAL+B8_PRODUTO+B8_LOCAL+B8_LOTECTL+B8_NUMLOTE+DTOS(B8_DTVALID)
			If !dbSeek(xFilial("SB8")+SBJ->BJ_COD+SBJ->BJ_LOCAL+SBJ->BJ_LOTECTL+SBJ->BJ_NUMLOTE+DTOS(SBJ->BJ_DTVALID))
				CriaLote("SBJ",SBJ->BJ_COD,SBJ->BJ_LOCAL,SBJ->BJ_LOTECTL, ;
					SBJ->BJ_NUMLOTE,"","","",Nil,"MN","","","IMPLAN", ;
					"","",SBJ->BJ_QINI,SBJ->BJ_QISEGUM,dDatabase,SBJ->BJ_DTVALID,.T.)
			EndIf
			SBJ->(dbSkip())
		EndDo			
		//��������������������������������������������������������������Ŀ
		//� Varrendo o SBK cria o registro no SBF                        �
		//����������������������������������������������������������������
		dbSelectArea("SBK")
		dbSeek(cSeek:=xFilial())
		While !SBK->(Eof()) .And. SBK->BK_FILIAL == cSeek
			dbSelectArea("SBF")
			dbSetOrder(1) // BF_FILIAL+BF_LOCAL+BF_LOCALIZ+BF_PRODUTO+BF_NUMSERI+BF_LOTECTL+BF_NUMLOTE
			If !dbSeek(xFilial("SBF")+SBK->BK_LOCAL+SBK->BK_LOCALIZ+SBK->BK_COD+SBK->BK_NUMSERI+SBK->BK_LOTECTL+SBK->BK_NUMLOTE)
				GravaSBF("SBK",.F.)
			EndIf
			SBK->(dbSkip())
		EndDo
		//��������������������������������������������������������������Ŀ
		//� Mostra relatorio com os logs de ocorrencia da importacao     �
		//����������������������������������������������������������������
		MataImpLog(aLogs)	
		dbCloseAll()
		OpenFile(SubStr(cNumEmp,1,2))
	EndIf
Else
	Aviso(STR0001,STR0024,{"Ok"}) // "Importa Dados"###"O RDMAKE para importacao de dados nao existe ou esta retornando dados invalidos !!!"
EndIf
RETURN

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    �MATAIMPLOG� Autor �Rodrigo de A. Sartorio � Data � 31/03/01 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Relatorio de ITENS que nao puderam ser importados por algum���
���          � tipo de inconsistencia nos dados passados                  ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � MATAIMP                                                    ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function MataImpLog(aLogs)
//��������������������������������������������������������������Ŀ
//� Variaveis obrigatorias dos programas de relatorio            �
//����������������������������������������������������������������
LOCAL titulo   := STR0017	//"Log de itens nao importados"
LOCAL cDesc1   := STR0018	//"Os itens que serao listados nao puderam ser listados por algum tipo de inconsistencia nos dados passados para a rotina."
LOCAL cDesc2   := STR0019	//"Acerte os dados e tente novamente."
LOCAL cDesc3   := ""
LOCAL cString  := ""
LOCAL wnrel    := "MATAIMP"

//��������������������������������������������������������������Ŀ
//� Variaveis tipo Private padrao de todos os relatorios         �
//����������������������������������������������������������������
PRIVATE aReturn:= {STR0020,1,STR0021, 2, 2, 1, "",1 }	//"Zebrado"###"Administracao"
PRIVATE nLastKey:= 0,cPerg:="      "

//��������������������������������������������������������������Ŀ
//� Envia controle para a funcao SETPRINT                        �
//����������������������������������������������������������������

wnrel:=	SetPrint(cString,wnrel,cPerg,@titulo,cDesc1,cDesc2,cDesc3,.F.,,,,,.F.)
If nLastKey = 27
	Set Filter to
	Return
Endif

SetDefault(aReturn,cString)

If nLastKey = 27
	Set Filter to
	Return
Endif

RptStatus({|lEnd| MtImpLog(@lEnd,wnRel,titulo,aLogs)},titulo)

Return NIL

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    �MtImpLog  � Autor � Rodrigo de A. Sartorio� Data � 31/03/01 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Chamada do Relatorio                                       ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � MATAIMP  			                                      ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function MtImpLog(lEnd,WnRel,titulo,aLogs)
//��������������������������������������������������������������Ŀ
//� Variaveis locais exclusivas deste programa                   �
//����������������������������������������������������������������
LOCAL Tamanho  := "M"
LOCAL nTipo    := 0
LOCAL cRodaTxt := STR0022	//"REGISTRO(S)"
LOCAL nCntImpr := 0
LOCAL i

//��������������������������������������������������������������Ŀ
//� Inicializa variaveis para controlar cursor de progressao     �
//����������������������������������������������������������������
SetRegua(Len(aLogs))

//�������������������������������������������������������������������Ŀ
//� Inicializa os codigos de caracter Comprimido/Normal da impressora �
//���������������������������������������������������������������������
nTipo  := IIF(aReturn[4]==1,15,18)

//��������������������������������������������������������������Ŀ
//� Contadores de linha e pagina                                 �
//����������������������������������������������������������������
PRIVATE li := 80 ,m_pag := 1

//����������������������������������������������������������Ŀ
//� Cria o cabecalho.                                        �
//������������������������������������������������������������
cabec1 := STR0023 // "Logs de ocorrencia"
cabec2 := ""

For i:=1 to Len(aLogs)
	IncRegua()
	If li > 58
		cabec(titulo,cabec1,cabec2,wnrel,Tamanho,nTipo)
	EndIf
	@ li,000 PSay aLogs[i,1]
	li++
	nCntImpr++
Next i

IF li != 80
	Roda(nCntImpr,cRodaTxt,Tamanho)
EndIF

If aReturn[5] = 1
	Set Printer To
	dbCommitAll()
	OurSpool(wnrel)
Endif
MS_FLUSH()

/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������Ŀ��
���Fun��o    �MatADDLog � Autor � Rodrigo de A. Sartorio� Data � 13/02/06 ���
�������������������������������������������������������������������������Ĵ��
���Descri��o � Adiciona item ao log                                       ���
�������������������������������������������������������������������������Ĵ��
��� Uso      � MATAIMP  			                                      ���
��������������������������������������������������������������������������ٱ�
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
Static Function MatADDLog(aLogs,cTexto,nEvento,cProduto,cArmazem,nCount1,nCount2)
Local nAcho:=aScan(aLogs,{|x| x[1] == cTexto .And. x[3] == cProduto .And. x[4] == cArmazem})		
If nAcho <= 0
	AADD(aLogs,{cTexto,nEvento,cProduto,cArmazem,nCount1,nCount2})
EndIf
RETURN 