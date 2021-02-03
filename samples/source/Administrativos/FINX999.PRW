#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWBROWSE.CH"
#Include "RPTDEF.CH"
#INCLUDE "RWMAKE.CH"

// #########################################################################################
// Projeto: 11.90
// Modulo : Financeiro
// Fonte  : FINX999.prw
// ---------+-------------------+-----------------------------------------------------------
// Data     | Autor             | Descricao
// ---------+-------------------+-----------------------------------------------------------
// 30/08/13 | Marcos Berto	    | Impressao de Boleto
// #########################################################################################
User Function FINX999(lPergunte, aMVPAR, aParams)
Local cMark       := GetMark()
Local cAliasQry   := ""
Local oPrint      := Nil
Local oMainWnd    := Nil
Local nTamGrp001  := TamSXG("001")[1]
Local nTamGrp002  := TamSXG("002")[1]
Local nTamGrp007  := TamSXG("007")[1]
Local nTamGrp011  := TamSXG("011")[1]
Local cArquivo    := ""
Local cDestPath   := ""
Local lExistParc  := .F.
Local nLoop       := 0
Local lContinua	  := .F.

Default lPergunte := .T.
Default aMVPAR    := {}
Default aParams   := {}

If lPergunte

	//Perguntas do rdmake
	lContinua := FINX999PRG()
	
	//Exibe o grupo de perguntas
	If lContinua
	
		//Monta a tabela temporária com os dados parametrizados
		cAliasQry := FINX999Tmp()
		
		If !(cAliasQry)->(Bof()) .Or. !(cAliasQry)->(Eof())
			FINX999Sel(cAliasQry, cMark)
			
			(cAliasQry)->(dbGoTop())
			
			//Define a tela onde será impressa a visualização		
			DEFINE DIALOG oMainWnd TITLE "Boleto" FROM 0,0 TO 800,600 PIXEL 
			
			oPrint := TMSPrinter():New("Boleto")
			oPrint:SetPortrait()
			
			While !(cAliasQry)->(Eof())
				If (cAliasQry)->E1_OK == cMark
					FINX999Imp(oPrint,cAliasQry)	
				EndIf
				(cAliasQry)->(dbSkip())	
			EndDo
	 
			oPrint:Preview()
		Else
			MsgAlert("Não há títulos disponíveis para a emissão do(s) boleto(s)."+CRLF+"Verifique os parâmetros informados e emita novamente a boleto.")
		EndIf
	
		(cAliasQry)->(dbCloseArea())
	EndIf

Else // SIGAPFS

	cDestPath := aParams[1]
	cArquivo  := aParams[2]
	
	MV_PAR01 := aMVPAR[1] // "Prefixo"
	MV_PAR02 := aMVPAR[1] // "Prefixo"
	MV_PAR03 := aMVPAR[2] // "Número"
	MV_PAR04 := aMVPAR[2] // "Número"
	MV_PAR05 := IIf(Empty(aMVPAR[4]), ""                        , aMVPAR[4]) // "Parcela"
	MV_PAR06 := IIf(Empty(aMVPAR[4]), Replicate("Z", nTamGrp011), aMVPAR[4]) // "Parcela"
	MV_PAR07 := ""
	MV_PAR08 := Replicate("Z", nTamGrp001)
	MV_PAR09 := ""
	MV_PAR10 := Replicate("Z", nTamGrp002)
	MV_PAR11 := ""
	MV_PAR12 := "99990101"
	MV_PAR13 := ""
	MV_PAR14 := "99990101"
	MV_PAR15 := ""
	MV_PAR16 := "ZZZZZZ"
	MV_PAR17 := aMVPAR[3] // "Banco"
	MV_PAR18 := "0"

	//Monta a tabela temporária com os dados parametrizados
	cAliasQry := FINX999Tmp()
		
	If !(cAliasQry)->(Bof()) .Or. !(cAliasQry)->(Eof())
			
		(cAliasQry)->(dbGoTop())

		oPrint := FWMsPrinter():New( cArquivo, IMP_PDF, .T.,, .T.,,,,,,, .F. ) // Inicia o relatório
		oPrint:cPathPDF := cDestPath
		oPrint:lInJob   := .T.
		oPrint:SetPortrait()
			
		While !(cAliasQry)->(Eof())
			
			If (cAliasQry)->E1_VALOR == (cAliasQry)->E1_SALDO
			
				FINX999Imp(oPrint, cAliasQry, lPergunte)
				
				lExistParc := .T. // Indica que existem parcelas para emissão do boleto
			
			EndIf
			
			(cAliasQry)->(dbSkip())
		EndDo

		If lExistParc

			// Caso já exista arquivo com o mesmo nome, o sistema irá sobrescrever.
			If File(cDestPath + cArquivo + ".pdf")
				FErase(cDestPath + cArquivo + ".pdf")
			EndIf

			oPrint:Print()

			// Exclui o arquivo .rel da pasta. Faz o Loop para garantir a exclusão, pois o arquivo pode estar em uso.
			If File(cDestPath + cArquivo + ".rel")
				While FErase(cDestPath + cArquivo + ".rel") != 0 .And. nLoop < 10
					Sleep(500)
					nLoop += 1
				EndDo
			EndIf

		Else

			JurMsgErro("Não foi possível refazer o(s) boleto(s), pois a(s) parcela(s) foram movimentadas.",,"Verifique a(s) parcela(s) da fatura.")

		EndIf

		(cAliasQry)->(dbCloseArea())
	EndIf

EndIf

Return

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999Imp
Monta e Imprime o Boleto

@author    TOTVS
@version   11.90
@since     06/09/13
/*/
//------------------------------------------------------------------------------------------
Static Function FINX999Imp(oPrint,cAliasQry,lPergunte)
Local aDados    := {}
Local cBanco    := ""
Local cImagem   := ""
Local cNumBco   := ""
Local cCart     := ""
Local cMsgLn1   := ""
Local cMsgLn2   := ""
Local cMsgLn3   := ""
Local cMsgLn4   := ""
Local cPictNN   := ""
Local nVlrAbat  := 0
Local nI        := 0

// Variáveis SIGAPFS - Caso use o pergunte, significa que a chamada não foi feita pelo SIGAPFS
Local nFatPPFS := 0
Local nFatNPFS := 0

Default cAliasQry := ""
Default lPergunte := .T.

nFatPPFS := IIf(lPergunte, 0, 20) // Fator para ajuste positivo conforme FWMsPrinter - Usado pelo SIGAPFS
nFatNPFS := IIf(lPergunte, 0, 8 ) // Fator para ajuste negativo conforme FWMsPrinter - Usado pelo SIGAPFS

cBanco := (cAliasQry)->A6_COD

cImagem := "\data\logos\"

Do Case
	Case cBanco == "237"
		
		cImagem 	+= "bradesco.bmp"	
		cNumBco 	:= "237-2"
		cCart		:= "22" 
		cMsgLn1	:= "(PAGÁVEL PREFERENCIALMENTE NA REDE BRADESCO OU BANCO POSTAL)" 								//Alterar conforme necessidade do cliente
		cMsgLn2	:= ""																		//Alterar conforme necessidade do cliente
		cMsgLn3	:= "(LIVRE PARA UTILIZAÇÃO DO CLIENTE)"
		cMsgLn4 	:= ""
		aPropImg	:= {290,120}
		cPictNN	:= "XXXXXXXXXXX-X"
		
	Case cBanco == "341"
		
		cImagem 	+= "itau.bmp"
		cNumBco 	:= "341-7"
		cCart		:= "" 
		cMsgLn1 	:= "ATÉ O VENCIMENTO PAGUE PREFERENCIALMENTE NO ITAÚ,"
		cMsgLn2 	:= "APÓS O VENCIMENTO PAGUE SOMENTE NO ITAÚ"
		cMsgLn3	:= "DE RESPONSABILIDADE DO BENEFICIÁRIO." 								//Alterar conforme necessidade do cliente
		cMsgLn4	:= "QUALQUER DÚVIDA SOBRE ESTE BOLETO, CONTATE O BENEFICIÁRIO."		//Alterar conforme necessidade do cliente
		aPropImg	:= {380,110}
		cPictNN	:= "XXX/XXXXXXXX-X"
	
	Case cBanco == "104"
		
		cImagem 	+= "cef.bmp"
		cNumBco 	:= "104-0"
		cCart		:= "SR" 																	//Alterar conforme necessidade do cliente
		cMsgLn1	:= "PREFERENCIALMENTE NAS CASAS LOTÉRICAS ATÉ O VALOR LIMITE"	
		cMsgLn2	:= ""	
		cMsgLn3	:= "(TEXTO DE RESPONSABILIDADE DO BENEFICIÁRIO)" 						//Alterar conforme necessidade do cliente
		cMsgLn4	:= ""	
		aPropImg	:= {270,120}
		cPictNN	:= "XXXXXXXXXX-X"
		
	Case cBanco == "399"
		
		cImagem 	+= "hsbc.bmp"
		cNumBco 	:= "399-9"
		cCart		:= "CNR" 
		cMsgLn1	:= "PAGAR PREFERENCIALMENTE EM AGÊNCIA DO HSBC"
		cMsgLn2	:= ""
		cMsgLn3	:= "(LIVRE PARA UTILIZAÇÃO DO CLIENTE)" 	     						//Alterar conforme necessidade do cliente
		cMsgLn4	:= ""																		//Alterar conforme necessidade do cliente
		aPropImg	:= {300,120}
		cPictNN	:= "XXXXXXXXXXXXX-XXXX"
		
	Case cBanco == "033"
		
		cImagem 	+= "santander.bmp"
		cNumBco 	:= "033-7"
		cCart		:= "102" 
		cMsgLn1	:= "(PAGAR PREFERENCIALMENTE NO GRUPO SANTANDER - GC)" 				//Alterar conforme necessidade do cliente
		cMsgLn2	:= ""																		//Alterar conforme necessidade do cliente																	//Alterar conforme necessidade do cliente
		cMsgLn3	:= "(TERMO DE RESPONSABILIDADE DO BENEFICIÁRIO)"
		cMsgLn4	:= ""
		aPropImg	:= {330,110}
		cPictNN	:= "XXXXXXXXXXXX-X"
	
	Case cBanco == "001"
		
		cImagem 	+= "bb.bmp"
		cNumBco 	:= "001-9"
		cCart		:= "11" 
		cMsgLn1	:= "(PAGÁVEL EM QUALQUER BANCO ATÉ O VENCIMENTO)" 					//Alterar conforme necessidade do cliente
		cMsgLn2	:= ""	
		cMsgLn3    := "(LIVRE PARA UTILIZAÇÃO DO CLIENTE)"
		cMsgLn4	:= ""																	//Alterar conforme necessidade do cliente
		aPropImg	:= {320,110}
		cPictNN	:= "XXXXXXXXXXX-X"

EndCase

nVlrAbat := SomaAbat((cAliasQry)->E1_PREFIXO,(cAliasQry)->E1_NUM,(cAliasQry)->E1_PARCELA,"R",1,dDataBase,(cAliasQry)->A1_COD,(cAliasQry)->A1_LOJA)

aAdd(aDados,cNumBco)																			//1 - Numero do Banco
aAdd(aDados,AllTrim((cAliasQry)->A6_AGENCIA))												//2 - Agencia
aAdd(aDados,AllTrim((cAliasQry)->A6_NUMCON))												//3 - Conta
aAdd(aDados,cImagem)																			//4 - Imagem
aAdd(aDados,AllTrim(SM0->M0_NOMECOM))														//5 - Beneficiario
aAdd(aDados,Transform(SM0->M0_CGC,"@R 99.999.999/9999-99"))								//6 - CNPJ Benef.
aAdd(aDados,AllTrim((cAliasQry)->A1_NOME))												//7 - Pagador
If (cAliasQry)->A1_PESSOA == "J"
	aAdd(aDados,Transform((cAliasQry)->A1_CGC,"@R 99.999.999/9999-99"))				//8 - CNPJ Pagador	
Else
	aAdd(aDados,Transform((cAliasQry)->A1_CGC,"@R 999.999.999-99")) 					//8 - CPF Pagador	
EndIf							
aAdd(aDados,(cAliasQry)->A1_ENDCOB)														//9 - End. Cob.
aAdd(aDados,(cAliasQry)->A1_BAIRROC)														//10- Bairro Cob.
aAdd(aDados,AllTrim((cAliasQry)->A1_MUNC))												//11- Munic. Cob.
aAdd(aDados,(cAliasQry)->A1_ESTC)															//12- Estado Cob.
aAdd(aDados,Transform((cAliasQry)->A1_CEPC,PesqPict("SA1","A1_CEP")))					//13- CEP Cob.
aAdd(aDados,Transform(FINX999NN(cAliasQry),"@R "+cPictNN))								//14- Nosso Numero
aAdd(aDados,FINX999LDg(cAliasQry)) 															//15- Linha Digitavel
aAdd(aDados,DtoC((cAliasQry)->E1_VENCTO)) 													//16- Vencimento
aAdd(aDados,DtoC((cAliasQry)->E1_EMISSAO))												//17- Emissao
aAdd(aDados,DtoC(dDataBase))																//18- Processamento
aAdd(aDados,Transform((cAliasQry)->E1_SALDO - nVlrAbat,PesqPict("SE1","E1_SALDO")))	//19- Valor
aAdd(aDados,cMsgLn1)																			//20- Local Pgto. Ln1
aAdd(aDados,cMsgLn2)																			//21- Local Pgto. Ln2			
aAdd(aDados,Iif(cBanco == "399","","R$"))													//22- Especie
aAdd(aDados,cCart)																			//23- Carteira
aAdd(aDados,Iif(cBanco == "399","","N"))													//24- Aceite
aAdd(aDados,(cAliasQry)->E1_TIPO)															//25- Tipo Doc.
aAdd(aDados,FINX999NCB(cAliasQry))															//26- Cod. Barras	
aAdd(aDados,cMsgLn3)																			//27- Instru. Ln1
aAdd(aDados,cMsgLn4)																			//28- Instru. Ln2

//Parametros de TFont.New()
//1.Nome da Fonte (Windows)
//3.Tamanho em Pixels
//5.Bold (T/F)

If lPergunte // Caso use o pergunte, significa que a chamada não foi feita pelo SIGAPFS e estará usando o TMSPrinter

	oPrint:StartPage()

	oFont8 		:= TFont():New("Arial"      ,9,8 ,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont11c 	:= TFont():New("Courier New",9,11,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10  	:= TFont():New("Arial"      ,9,10,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont14  	:= TFont():New("Arial"      ,9,14,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont20  	:= TFont():New("Arial"      ,9,20,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont21  	:= TFont():New("Arial"      ,9,21,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont16n 	:= TFont():New("Arial"      ,9,16,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont15  	:= TFont():New("Arial"      ,9,15,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont15n 	:= TFont():New("Arial"      ,9,15,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont14n 	:= TFont():New("Arial"      ,9,14,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont24  	:= TFont():New("Arial"      ,9,24,.T.,.T.,5,.T.,5,.T.,.F.)

Else // Quando a chamada for feita pelo SIGAPFS estará usando o FWMSPrinter por isso os tamanhos das fontes são diferentes

	oFont8 		:= TFont():New("Arial"      ,9,10,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont11c 	:= TFont():New("Courier New",9,13,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10  	:= TFont():New("Arial"      ,9,12,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont14  	:= TFont():New("Arial"      ,9,16,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont20  	:= TFont():New("Arial"      ,9,22,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont21  	:= TFont():New("Arial"      ,9,23,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont16n 	:= TFont():New("Arial"      ,9,18,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont15  	:= TFont():New("Arial"      ,9,17,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont15n 	:= TFont():New("Arial"      ,9,17,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont14n 	:= TFont():New("Arial"      ,9,16,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont24  	:= TFont():New("Arial"      ,9,26,.T.,.T.,5,.T.,5,.T.,.F.)
EndIf

oPrint:StartPage()   // Inicia uma nova página

/******************/
/* PRIMEIRA PARTE */
/******************/
 
oPrint:Line (0150,500,0070, 500)
oPrint:Line (0150,710,0070, 710)

oPrint:SayBitmap(40,100,cImagem,aPropImg[1],aPropImg[2])	//IMAGEM
//oPrint:Say  (0084,100,"NOME DO BANCO",oFont14 )			//(OU) NOME DO BANCO

oPrint:Say  (0075 + (3*nFatPPFS),513,aDados[1],oFont21)

oPrint:Say  (0084 + nFatPPFS,1900,"Comprovante de Entrega",oFont10)
oPrint:Line (0150,100,0150,2300)

oPrint:Say  (0150 + nFatPPFS,100 ,"Beneficiário",oFont8)
oPrint:Say  (0200 + nFatPPFS,100 ,aDados[5],oFont10)

oPrint:Say  (0150 + nFatPPFS,1060,"Agência/Código do Beneficiário",oFont8)
oPrint:Say  (0200 + nFatPPFS,1060,aDados[2]+"/"+aDados[3],oFont10)

oPrint:Say  (0150 + nFatPPFS,1510,"Nro.Documento",oFont8)
oPrint:Say  (0200 + nFatPPFS,1510,aDados[14],oFont10)
 
oPrint:Say  (0250 + nFatPPFS,100 ,"Pagador",oFont8)
oPrint:Say  (0300 + nFatPPFS,100 ,aDados[7],oFont10)

oPrint:Say  (0250 + nFatPPFS,1060,"Vencimento",oFont8)
oPrint:Say  (0300 + nFatPPFS,1060,aDados[16],oFont10)

oPrint:Say  (0250 + nFatPPFS,1510,"Valor do Documento",oFont8)
oPrint:Say  (0300 + nFatPPFS,1550,aDados[19],oFont10)

oPrint:Say  (0400 + nFatPPFS,0100,"Recebi(emos) o boleto/título",oFont10)
oPrint:Say  (0450 + nFatPPFS,0100,"com as características acima.",oFont10)
oPrint:Say  (0350 + nFatPPFS,1060,"Data",oFont8)
oPrint:Say  (0350 + nFatPPFS,1410,"Assinatura",oFont8)
oPrint:Say  (0450 + nFatPPFS,1060,"Data",oFont8)
oPrint:Say  (0450 + nFatPPFS,1410,"Entregador",oFont8)

oPrint:Line (0250, 100,0250,1900 )
oPrint:Line (0350, 100,0350,1900 )
oPrint:Line (0450,1050,0450,1900 )
oPrint:Line (0550, 100,0550,2300 )

oPrint:Line (0550,1050,0150,1050 )
oPrint:Line (0550,1400,0350,1400 )
oPrint:Line (0350,1500,0150,1500 )
oPrint:Line (0550,1900,0150,1900 )

oPrint:Say  (0165 + nFatPPFS,1910,"(  )Mudou-se",oFont8)
oPrint:Say  (0205 + nFatPPFS,1910,"(  )Ausente",oFont8)
oPrint:Say  (0245 + nFatPPFS,1910,"(  )Não existe nº indicado",oFont8)
oPrint:Say  (0285 + nFatPPFS,1910,"(  )Recusado",oFont8)
oPrint:Say  (0325 + nFatPPFS,1910,"(  )Não procurado",oFont8)
oPrint:Say  (0365 + nFatPPFS,1910,"(  )Endereço insuficiente",oFont8)
oPrint:Say  (0405 + nFatPPFS,1910,"(  )Desconhecido",oFont8)
oPrint:Say  (0445 + nFatPPFS,1910,"(  )Falecido",oFont8)
oPrint:Say  (0485 + nFatPPFS,1910,"(  )Outros(anotar no verso)",oFont8)

/*****************/
/* SEGUNDA PARTE */
/*****************/

//Pontilhado separador
For nI := 100 to 2300 step 50
	oPrint:Line(0580, nI,0580, nI+30)
Next nI

oPrint:Line (0710,100,0710,2300)
oPrint:Line (0710,500,0630, 500)
oPrint:Line (0710,710,0630, 710)

oPrint:SayBitmap(590,100,cImagem,aPropImg[1],aPropImg[2])		//IMAGEM
//oPrint:Say  (0644,100,"NOME DO BANCO",oFont14)					//(OU) NOME DO BANCO

oPrint:Say  (0635 + (3*nFatPPFS),513,aDados[1],oFont21 )

oPrint:Say  (0600 + nFatPPFS,1900,"Recibo do Pagador",oFont10)

oPrint:Say  (0644 + (2*nFatPPFS),755,aDados[15],oFont15n)

oPrint:Line (0810,100,0810,2300 )
oPrint:Line (0910,100,0910,2300 )
oPrint:Line (0980,100,0980,2300 )
oPrint:Line (1050,100,1050,2300 )

oPrint:Line (0910,500,1050,500)
oPrint:Line (0980,750,1050,750)
oPrint:Line (0910,1000,1050,1000)
oPrint:Line (0910,1300,0980,1300)
oPrint:Line (0910,1480,1050,1480)

oPrint:Say  (0710 + nFatPPFS,100 ,"Local de Pagamento",oFont8)
oPrint:Say  (0725 + nFatPPFS,400 ,aDados[20],oFont10)
oPrint:Say  (0765 + nFatPPFS,400 ,aDados[21],oFont10)

oPrint:Say  (0710 + nFatPPFS,1810,"Vencimento",oFont8)
nCol := 1810+(374-(Len(aDados[16])*22))
oPrint:Say  (0750 + nFatPPFS,nCol,aDados[16],oFont11c)

oPrint:Say  (0810 + nFatPPFS,100 ,"Beneficiário",oFont8)
oPrint:Say  (0850 + nFatPPFS,100 ,aDados[5]+" - CNPJ: "+aDados[6],oFont10)

oPrint:Say  (0810 + nFatPPFS,1810,"Agência/Código do Beneficiário",oFont8)
nCol := 1810+(374-(Len(aDados[2]+aDados[3])+1)*22)
oPrint:Say  (0850 + nFatPPFS,nCol,aDados[2]+"/"+aDados[3],oFont11c)
 
oPrint:Say  (0910 + nFatPPFS,100 ,"Data do Documento",oFont8)
oPrint:Say  (0940 + nFatPPFS,100, aDados[17],oFont10)

oPrint:Say  (0910 + nFatPPFS,505 ,"Nro.Documento",oFont8)
oPrint:Say  (0940 + nFatPPFS,605 ,aDados[14],oFont10)

oPrint:Say  (0910 + nFatPPFS,1005,"Espécie Doc.",oFont8)
oPrint:Say  (0940 + nFatPPFS,1050,aDados[25],oFont10)

oPrint:Say  (0910 + nFatPPFS,1305,"Aceite",oFont8)
oPrint:Say  (0940 + nFatPPFS,1400,aDados[24],oFont10)

oPrint:Say  (0910 + nFatPPFS,1485,"Data do Processamento",oFont8)
oPrint:Say  (0940 + nFatPPFS,1550,aDados[18],oFont10)

oPrint:Say  (0910 + nFatPPFS,1810,"Nosso Número",oFont8)
nCol := 1880+(374-(Len(aDados[14])*22))
oPrint:Say  (0940 + nFatPPFS,nCol,aDados[14],oFont11c)

oPrint:Say  (0980 + nFatPPFS,100 ,"Uso do Banco",oFont8)

oPrint:Say  (0980 + nFatPPFS,505 ,"Carteira",oFont8)
oPrint:Say  (1010 + nFatPPFS,555 ,aDados[23],oFont10)

oPrint:Say  (0980 + nFatPPFS,755 ,"Espécie",oFont8)
oPrint:Say  (1010 + nFatPPFS,805 ,aDados[22],oFont10)

oPrint:Say  (0980 + nFatPPFS,1005,"Quantidade",oFont8)
oPrint:Say  (0980 + nFatPPFS,1485,"Valor",oFont8)

oPrint:Say  (0980 + nFatPPFS,1810,"Valor do Documento",oFont8)
nCol := 1810+(374-(len(aDados[19])*22))
oPrint:Say  (1010 + nFatPPFS,nCol,aDados[19],oFont11c)

oPrint:Say  (1050 + nFatPPFS,100 ,"Instruções",oFont8)
oPrint:Say  (1150 + nFatPPFS,100,aDados[27]+" "+aDados[28],oFont10)

oPrint:Say  (1050 + nFatPPFS,1810,"(-)Desconto/Abatimento"	,oFont8)
oPrint:Say  (1120 + nFatPPFS,1810,"(-)Outras Deduções"			,oFont8)
oPrint:Say  (1190 + nFatPPFS,1810,"(+)Mora/Multa"				,oFont8)
oPrint:Say  (1260 + nFatPPFS,1810,"(+)Outros Acréscimos"		,oFont8)
oPrint:Say  (1330 + nFatPPFS,1810,"(=)Valor Cobrado"			,oFont8)

oPrint:Say  (1400 + nFatPPFS,100 ,"Pagador",oFont8)
oPrint:Say  (1430 + nFatPPFS,400 ,aDados[7]+" - "+aDados[8],oFont10)
oPrint:Say  (1483 + nFatPPFS,400 ,aDados[9],oFont10)
oPrint:Say  (1536 + nFatPPFS,400 ,aDados[13],oFont10)
oPrint:Say  (1536 + nFatPPFS,800 ,aDados[10],oFont10)
oPrint:Say  (1536 + nFatPPFS,1300,aDados[11]+"-"+aDados[12],oFont10)

oPrint:Say  (1605 + nFatPPFS,100 ,"Sacador/Avalista",oFont8)
oPrint:Say  (1645 + nFatPPFS,1500,"Autenticação Mecânica",oFont8)

oPrint:Line (0710,1800,1400,1800 ) 
oPrint:Line (1120,1800,1120,2300 )
oPrint:Line (1190,1800,1190,2300 )
oPrint:Line (1260,1800,1260,2300 )
oPrint:Line (1330,1800,1330,2300 )
oPrint:Line (1400,100 ,1400,2300 )
oPrint:Line (1640,100 ,1640,2300 )

/******************/
/* TERCEIRA PARTE */
/******************/

For nI := 100 to 2300 step 50
	oPrint:Line(1880, nI, 1880, nI+30)
Next nI

oPrint:SayBitmap(1890,100,cImagem,aPropImg[1],aPropImg[2])	//IMAGEM
//oPrint:Say (1934,100,"NOME DO BANCO",oFont14 ) 			//(OU) NOME DO BANCO

oPrint:Line (2000,100,2000,2300)
oPrint:Line (2000,500,1920, 500)
oPrint:Line (2000,710,1920, 710)

oPrint:Say  (1925 + (3*nFatPPFS),513,aDados[1],oFont21 )
oPrint:Say  (1934 + (2*nFatPPFS),755,aDados[15],oFont15n)

oPrint:Line (2100,100,2100,2300 )
oPrint:Line (2200,100,2200,2300 )
oPrint:Line (2270,100,2270,2300 )
oPrint:Line (2340,100,2340,2300 )

oPrint:Line (2200,500 ,2340,500 )
oPrint:Line (2270,750 ,2340,750 )
oPrint:Line (2200,1000,2340,1000)
oPrint:Line (2200,1300,2270,1300)
oPrint:Line (2200,1480,2340,1480)

oPrint:Say  (2000 + nFatPPFS,100 ,"Local de Pagamento",oFont8)
oPrint:Say  (2015 + nFatPPFS,400 ,aDados[20],oFont10)
oPrint:Say  (2055 + nFatPPFS,400 ,aDados[21],oFont10)
           
oPrint:Say  (2000 + nFatPPFS,1810,"Vencimento",oFont8)
nCol	 	 := 1810+(374-(Len(aDados[16])*22))
oPrint:Say  (2040 + nFatPPFS,nCol,aDados[16],oFont11c)

oPrint:Say  (2100 + nFatPPFS,100 ,"Beneficiário",oFont8)
oPrint:Say  (2140 + nFatPPFS,100 ,aDados[5]+" - CNPJ: "+aDados[6],oFont10)

oPrint:Say  (2100 + nFatPPFS,1810,"Agência/Código Cedente",oFont8)
nCol 	 := 1810+(374-((Len(aDados[2]+aDados[3])+1)*22))
oPrint:Say  (2140 + nFatPPFS,nCol,aDados[2]+"/"+aDados[3] ,oFont11c)

oPrint:Say  (2200 + nFatPPFS,100,"Data do Documento",oFont8)
oPrint:Say  (2230 + nFatPPFS,100,aDados[17],oFont10)

oPrint:Say  (2200 + nFatPPFS,505,"Nro.Documento",oFont8)
oPrint:Say  (2230 + nFatPPFS,605,aDados[14],oFont10)

oPrint:Say  (2200 + nFatPPFS,1005,"Espécie Doc.",oFont8)
oPrint:Say  (2230 + nFatPPFS,1050,aDados[25],oFont10)

oPrint:Say  (2200 + nFatPPFS,1305,"Aceite",oFont8)
oPrint:Say  (2230 + nFatPPFS,1400,aDados[24],oFont10)

oPrint:Say  (2200 + nFatPPFS,1485,"Data do Processamento",oFont8)
oPrint:Say  (2230 + nFatPPFS,1550,aDados[18],oFont10)

oPrint:Say  (2200 + nFatPPFS,1810,"Nosso Número",oFont8)
nCol 	 := 1880+(374-(Len(aDados[14])*22))
oPrint:Say  (2230 + nFatPPFS,nCol,aDados[14],oFont11c)

oPrint:Say  (2270 + nFatPPFS,100 ,"Uso do Banco",oFont8)

oPrint:Say  (2270 + nFatPPFS,505 ,"Carteira",oFont8)
oPrint:Say  (2300 + nFatPPFS,555 ,aDados[23],oFont10)

oPrint:Say  (2270 + nFatPPFS,755 ,"Espécie",oFont8)
oPrint:Say  (2300 + nFatPPFS,805 ,aDados[22],oFont10)

oPrint:Say  (2270 + nFatPPFS,1005,"Quantidade",oFont8)
oPrint:Say  (2270 + nFatPPFS,1485,"Valor",oFont8)

oPrint:Say  (2270 + nFatPPFS,1810,"Valor do Documento",oFont8)
nCol 	 := 1810+(374-(Len(aDados[19])*22))
oPrint:Say  (2300 + nFatPPFS,nCol,aDados[19],oFont11c)

oPrint:Say  (2340 + nFatPPFS,100,"Instruções",oFont8)
oPrint:Say  (2440 + nFatPPFS,100,aDados[27]+" "+aDados[28],oFont10)

oPrint:Say  (2340 + nFatPPFS,1810,"(-)Desconto/Abatimento"	,oFont8)
oPrint:Say  (2410 + nFatPPFS,1810,"(-)Outras Deduções"		,oFont8)
oPrint:Say  (2480 + nFatPPFS,1810,"(+)Mora/Multa"				,oFont8)
oPrint:Say  (2550 + nFatPPFS,1810,"(+)Outros Acréscimos"		,oFont8)
oPrint:Say  (2620 + nFatPPFS,1810,"(=)Valor Cobrado"			,oFont8)

oPrint:Say  (2690 + nFatPPFS,100 ,"Pagador",oFont8)
oPrint:Say  (2700 + nFatPPFS,400 ,aDados[7]+" - "+aDados[8],oFont10)
oPrint:Say  (2753 + nFatPPFS,400 ,aDados[9],oFont10)
oPrint:Say  (2806 + nFatPPFS,400 ,aDados[13],oFont10)
oPrint:Say  (2806 + nFatPPFS,600 ,aDados[10],oFont10)
oPrint:Say  (2806 + nFatPPFS,1200,aDados[11]+"-"+aDados[12],oFont10)

oPrint:Say  (2878 - nFatNPFS,100 ,"Sacador/Avalista",oFont8)
oPrint:Say  (2878 - nFatNPFS,1500,"Autenticação Mecânica - Ficha de Compensação" ,oFont8)

oPrint:Line (2000,1800,2690,1800)
oPrint:Line (2410,1800,2410,2300)
oPrint:Line (2480,1800,2480,2300)
oPrint:Line (2550,1800,2550,2300)
oPrint:Line (2620,1800,2620,2300)
oPrint:Line (2690,100 ,2690,2300)

oPrint:Line (2850,100,2850,2300)

If lPergunte // Caso use o pergunte, significa que a chamada não foi feita pelo SIGAPFS e estará usando o TMSPrinter
	MSBAR("INT25",25.5,1,aDados[26],oPrint,.F.,Nil,Nil,0.025,1.5,Nil,Nil,"A",.F.)
Else // Quando a chamada for feita pelo SIGAPFS estará usando o FWMSPrinter por isso a inclusão do código de barras é diferente
	oPrint:FWMsBar("INT25",67.5,2.2,aDados[26],oPrint,.F.,Nil,Nil,0.025,0.8,Nil,Nil,"A",.F.)
EndIf

oPrint:EndPage()

aDados := Nil

Return

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999Sel
Monta a tela de seleção de títulos.

@author    TOTVS
@version   11.90
@since     30/08/13
/*/
//------------------------------------------------------------------------------------------
Static Function FINX999Sel(cAliasTmp,cMark)
Local oDlg
Local oBrowse
Local oColumn

DEFAULT cAliasTmp	:= ""
DEFAULT cMark		:= ""

If !Empty(cAliasTmp)
	DEFINE MSDIALOG oDlg TITLE "Seleção de Títulos" FROM 0,0 TO 600,800 PIXEL	
	
	dbSelectArea(cAliasTmp)
	
	DEFINE FWBROWSE oBrowse DATA TABLE ALIAS cAliasTmp NO REPORT OF oDlg		
	
	ADD MARKCOLUMN oColumn DATA { || If((cAliasTmp)->E1_OK == cMark,'LBOK','LBNO') } DOUBLECLICK { || FINX999Mrk(cAliasTmp,cMark) } HEADERCLICK { |oBrowse| FINX999IMk(cAliasTmp,cMark), oBrowse:Refresh() } OF oBrowse		
	
	ADD COLUMN oColumn DATA { || (cAliasTmp)->E1_PREFIXO   											} TITLE RetTitle("E1_PREFIXO"	)  	OF oBrowse
	ADD COLUMN oColumn DATA { || (cAliasTmp)->E1_NUM   												} TITLE RetTitle("E1_NUM"		)  	OF oBrowse
	ADD COLUMN oColumn DATA { || (cAliasTmp)->E1_PARCELA   											} TITLE RetTitle("E1_PARCELA"	)  	OF oBrowse
	ADD COLUMN oColumn DATA { || (cAliasTmp)->E1_NUMBOR   											} TITLE RetTitle("E1_NUMBOR"		)  	OF oBrowse
	ADD COLUMN oColumn DATA { || (cAliasTmp)->E1_EMISSAO   											} TITLE RetTitle("E1_EMISSAO"	)  	OF oBrowse
	ADD COLUMN oColumn DATA { || (cAliasTmp)->E1_VENCREA   											} TITLE RetTitle("E1_VENCREA"	)  	OF oBrowse
	ADD COLUMN oColumn DATA { || Transform((cAliasTmp)->E1_SALDO, "@E 9,999,999,999,999.99")  	} TITLE RetTitle("E1_SALDO"		)  	OF oBrowse
	ADD COLUMN oColumn DATA { || (cAliasTmp)->A1_COD 													} TITLE RetTitle("E1_CLIENTE"	)  	OF oBrowse	
	ADD COLUMN oColumn DATA { || (cAliasTmp)->A1_LOJA   												} TITLE RetTitle("E1_LOJA"		) 	OF oBrowse	
	ADD COLUMN oColumn DATA { || (cAliasTmp)->A1_NOME   												} TITLE RetTitle("A1_NOME"		) 	OF oBrowse
	
	ACTIVATE FWBROWSE oBrowse
	
	ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{|| oDlg:End()},{|| oDlg:End()},,)
EndIf

Return

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999Mrk
Atualiza a marcação dos títulos para a geração do boleto

@author    TOTVS
@version   11.90
@since     02/09/13
/*/
//------------------------------------------------------------------------------------------
Static Function FINX999Mrk(cAliasTmp, cMark)
DEFAULT cAliasTmp := ""
DEFAULT cMark:= ""

If (cAliasTmp)->E1_OK == cMark
	RecLock(cAliasTmp,.F.)
	(cAliasTmp)->E1_OK := ""
	(cAliasTmp)->(MsUnlock())
Else
	RecLock(cAliasTmp,.F.)
	(cAliasTmp)->E1_OK := cMark
	(cAliasTmp)->(MsUnlock())
EndIf

Return

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999IMk
Inverte a marcação dos títulos para a geração do boleto

@author    TOTVS
@version   11.90
@since     02/09/13
/*/
//------------------------------------------------------------------------------------------
Static Function FINX999IMk(cAliasTmp, cMark)

Local aAreaTmp := {}

DEFAULT cAliasTmp := ""
DEFAULT cMark:= ""

dbSelectArea(cAliasTmp)
aAreaTmp := (cAliasTmp)->(GetArea())
(cAliasTmp)->(dbGoTop())

While !(cAliasTmp)->(Eof())
	FINX999Mrk(cAliasTmp,cMark)
	(cAliasTmp)->(dbSkip())
EndDo

(cAliasTmp)->(RestArea(aAreaTmp))

Return

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999VIB
Valida o código do banco informado na pergunta "Portador" da pergunta FINX999

@author    TOTVS
@version   11.90
@since     30/08/13

@return lRet - Banco válido ou não
/*/
//------------------------------------------------------------------------------------------
User Function FINX999VIB()
Local lRet       := .T.
Local cPortador  := MV_PAR17
Local aBanco     := {}

aAdd(aBanco,"001")
aAdd(aBanco,"237")
aAdd(aBanco,"104")
aAdd(aBanco,"399")
aAdd(aBanco,"341")
aAdd(aBanco,"033")

/*
	BANCOS VALIDOS
	-----------------------------------
	001 - Banco do Brasil
	237 - Banco Bradesco
	104 - Caixa Economica Federal
	399 - HSBC
	341 - Itau
	033 - Santander
	-----------------------------------
*/
	
If aScan(aBanco,{ |cBanco| Alltrim(cBanco) == Alltrim(cPortador)  }) <= 0
	lRet := .F.
	MsgAlert("O banco informado não é válido para a impressão deste modelo de boleto.")
EndIf

Return lRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999TMP
Criação do arquivo temporário Clientes X Títulos X Banco

@author    TOTVS
@version   11.90
@since     30/08/13

@return cAliasTrb - Alias do Arquivo temporário
/*/
//------------------------------------------------------------------------------------------
Static Function FINX999Tmp()
Local aStruct       := {}
Local cAliasQry	    := GetNextAlias()
Local cAliasTrb	    := GetNextAlias()
Local cCampo        := ""
Local cNotIn        := '%' + FormatIn(MVABATIM,"/") + "%"
Local nX            := 0
Local xConteudo	    := ""

BeginSQL Alias cAliasQry
	SELECT	SE1.E1_PREFIXO,	SE1.E1_NUM,		SE1.E1_PARCELA,	SE1.E1_TIPO,
			SE1.E1_EMISSAO,	SE1.E1_VENCREA,	SE1.E1_NUMBOR,	SE1.E1_SALDO,
			SE1.E1_VENCTO,	SE1.E1_OK,		SE1.E1_VALOR,
			SA6.A6_COD,		SA6.A6_AGENCIA,	SA6.A6_NUMCON,	SA6.A6_NOME,		
			SA6.A6_DVCTA,
			SA1.A1_COD,		SA1.A1_NOME,		SA1.A1_LOJA, 		SA1.A1_END,		
			SA1.A1_ENDCOB,	SA1.A1_BAIRRO,	SA1.A1_BAIRROC,	SA1.A1_MUN,		
			SA1.A1_MUNC,		SA1.A1_EST,		SA1.A1_ESTC,		SA1.A1_CEP,		
			SA1.A1_CEPC,		SA1.A1_CGC,		SA1.A1_PESSOA
	FROM	%Table:SE1% SE1
			INNER JOIN %Table:SA6% SA6 ON
			SA6.A6_FILIAL			= %XFilial:SA6%
			AND SA6.A6_COD			= SE1.E1_PORTADO
			AND SA6.A6_AGENCIA	= SE1.E1_AGEDEP
			AND SA6.A6_NUMCON		= SE1.E1_CONTA
			AND SA6.%NotDel%
			INNER JOIN %Table:SA1% SA1 ON
			SA1.A1_FILIAL			= %XFilial:SA1%
			AND SA1.A1_COD			= SE1.E1_CLIENTE
			AND SA1.A1_LOJA		= SE1.E1_LOJA
			AND SA1.%NotDel% 
	WHERE	SE1.E1_FILIAL			=	%XFilial:SE1%
			AND SE1.E1_PREFIXO	BETWEEN	%Exp:MV_PAR01% AND %Exp:MV_PAR02%
			AND SE1.E1_NUM			BETWEEN	%Exp:MV_PAR03% AND %Exp:MV_PAR04%
			AND SE1.E1_PARCELA	BETWEEN	%Exp:MV_PAR05% AND %Exp:MV_PAR06%
			AND SE1.E1_TIPO		NOT IN		%Exp:cNotIn%
			AND SE1.E1_CLIENTE	BETWEEN	%Exp:MV_PAR07% AND %Exp:MV_PAR08%
			AND SE1.E1_LOJA		BETWEEN	%Exp:MV_PAR09% AND %Exp:MV_PAR10%
			AND SE1.E1_EMISSAO	BETWEEN	%Exp:MV_PAR11% AND %Exp:MV_PAR12%
			AND SE1.E1_VENCREA	BETWEEN	%Exp:MV_PAR13% AND %Exp:MV_PAR14%
			AND SE1.E1_NUMBOR		BETWEEN	%Exp:MV_PAR15% AND %Exp:MV_PAR16%
			AND SE1.E1_PORTADO	=			%Exp:MV_PAR17%
			AND SE1.E1_SITUACA	=			%Exp:MV_PAR18%
			AND SE1.E1_SALDO		>			0
			AND SE1.E1_PORTADO	<>			' '
			AND SE1.%NotDel%
	ORDER BY %Order:SE1%
EndSQL

aAdd(aStruct,{"E1_PREFIXO"	,"C", TamSX3("E1_PREFIXO")[1]	, TamSX3("E1_PREFIXO")[2]}	)
aAdd(aStruct,{"E1_NUM"		,"C", TamSX3("E1_NUM")[1]		, TamSX3("E1_NUM")[2]}		)
aAdd(aStruct,{"E1_PARCELA"	,"C", TamSX3("E1_PARCELA")[1]	, TamSX3("E1_PARCELA")[2]}	)
aAdd(aStruct,{"E1_TIPO"		,"C", TamSX3("E1_TIPO")[1]		, TamSX3("E1_TIPO")[2]}		)
aAdd(aStruct,{"E1_EMISSAO"	,"D", TamSX3("E1_EMISSAO")[1]	, TamSX3("E1_EMISSAO")[2]}	)
aAdd(aStruct,{"E1_NUMBOR"	,"C", TamSX3("E1_NUMBOR")[1]	, TamSX3("E1_NUMBOR")[2]}	)
aAdd(aStruct,{"E1_OK"		,"C", TamSX3("E1_OK")[1]		, TamSX3("E1_OK")[2]}		)
aAdd(aStruct,{"E1_VALOR"	,"N", TamSX3("E1_VALOR")[1]		, TamSX3("E1_VALOR")[2]}	)
aAdd(aStruct,{"E1_SALDO"	,"N", TamSX3("E1_SALDO")[1]		, TamSX3("E1_SALDO")[2]}	)
aAdd(aStruct,{"E1_VENCREA"	,"D", TamSX3("E1_VENCREA")[1]	, TamSX3("E1_VENCREA")[2]}	)
aAdd(aStruct,{"E1_VENCTO"	,"D", TamSX3("E1_VENCTO")[1]	, TamSX3("E1_VENCTO")[2]}	)
aAdd(aStruct,{"A1_COD"		,"C", TamSX3("A1_COD")[1]		, TamSX3("A1_COD")[2]}		)
aAdd(aStruct,{"A1_BAIRRO"	,"C", TamSX3("A1_BAIRRO")[1]	, TamSX3("A1_BAIRRO")[2]}	)
aAdd(aStruct,{"A1_BAIRROC"	,"C", TamSX3("A1_BAIRROC")[1]	, TamSX3("A1_BAIRROC")[2]}	)
aAdd(aStruct,{"A1_CEP"		,"C", TamSX3("A1_CEP")[1]		, TamSX3("A1_CEP")[2]}		)
aAdd(aStruct,{"A1_CEPC"		,"C", TamSX3("A1_CEPC")[1]		, TamSX3("A1_CEPC")[2]}		)
aAdd(aStruct,{"A1_CGC"		,"C", TamSX3("A1_CGC")[1]		, TamSX3("A1_CGC")[2]}		)
aAdd(aStruct,{"A1_LOJA"		,"C", TamSX3("A1_LOJA ")[1]		, TamSX3("A1_LOJA ")[2]}	)
aAdd(aStruct,{"A1_NOME"		,"C", TamSX3("A1_NOME")[1]		, TamSX3("A1_NOME")[2]}		)
aAdd(aStruct,{"A1_END"		,"C", TamSX3("A1_END")[1]		, TamSX3("A1_END")[2]}		)
aAdd(aStruct,{"A1_ENDCOB"	,"C", TamSX3("A1_ENDCOB")[1]	, TamSX3("A1_ENDCOB")[2]}	)
aAdd(aStruct,{"A1_EST"		,"C", TamSX3("A1_EST")[1]		, TamSX3("A1_EST")[2]}		)
aAdd(aStruct,{"A1_ESTC"		,"C", TamSX3("A1_ESTC")[1]		, TamSX3("A1_ESTC")[2]}		)
aAdd(aStruct,{"A1_MUN"		,"C", TamSX3("A1_MUN")[1]		, TamSX3("A1_MUN")[2]}		)
aAdd(aStruct,{"A1_MUNC"		,"C", TamSX3("A1_MUNC")[1]		, TamSX3("A1_MUNC")[2]}		)
aAdd(aStruct,{"A1_PESSOA"	,"C", TamSX3("A1_PESSOA")[1]	, TamSX3("A1_PESSOA")[2]}	)
aAdd(aStruct,{"A6_COD"		,"C", TamSX3("A6_COD")[1]		, TamSX3("A6_COD")[2]}		)
aAdd(aStruct,{"A6_AGENCIA"	,"C", TamSX3("A6_AGENCIA")[1]	, TamSX3("A6_AGENCIA")[2]}	)
aAdd(aStruct,{"A6_NUMCON"	,"C", TamSX3("A6_NUMCON")[1]	, TamSX3("A6_NUMCON")[2]}	)
aAdd(aStruct,{"A6_NOME"		,"C", TamSX3("A6_NOME")[1]		, TamSX3("A6_NOME")[2]}		)
aAdd(aStruct,{"A6_DVCTA"	,"C", TamSX3("A6_DVCTA")[1]		, TamSX3("A6_DVCTA")[2]}	)

//Cria o arquivo temporário
cAliasTrb := CriaTrab(aStruct,.T.)
DbUseArea(.T.,__Localdrive, cAliasTrb,cAliasTrb)
IndRegua(cAliasTrb,cAliasTrb,"E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO")

dbSelectArea(cAliasQry)
While !(cAliasQry)->(Eof())

	RecLock(cAliasTrb,.T.)
	
	For nX := 1 to Len(aStruct)
		cCampo := aStruct[nX][1]
		
		If aStruct[nX][2] == "D"
			xConteudo := StoD((cAliasQry)->&cCampo)
		Else
			xConteudo := 	(cAliasQry)->&cCampo
		EndIf
		
		(cAliasTrb)->&cCampo := xConteudo
	Next nX
	
	(cAliasTrb)->(MsUnlock())
	(cAliasQry)->(dbSkip())
	
EndDo

(cAliasQry)->(dbCloseArea())

Return(cAliasTrb)

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999NN
Geração valor do "Nosso Numero"

@author    TOTVS
@version   11.90
@since     03/09/13

@param cBanco		- Cod. do Banco
@param	cAliasTmp	- Alias da tabela temporária

@return cRet 		- Cod. do Nosso Número
/*/
//------------------------------------------------------------------------------------------
Static Function FINX999NN(cAliasTmp,lDV)
Local cBanco	:= ""
Local cAux		:= ""
Local cNum		:= ""
Local cDV		:= ""
Local cRet		:= ""
Local cBco		:= ""

DEFAULT cAliasTmp	:= ""
DEFAULT lDV	 	:= .T.

cBanco := (cAliasTmp)->A6_COD

Do Case
	Case cBanco == "237" //Bradesco
	
		cNum	:= PadL(AllTrim((cAliasTmp)->E1_NUM),11,"0")
		cDV		:= FINX999M10("99"+cNum) //99 - Numero Fornecido pelo Banco
			
		cRet	:= cNum+cDV
			
	Case cBanco == "341" //Itau

		cAux	:= "110" //Número Fornecido pelo Banco
		cNum	:= PadL(AllTrim((cAliasTmp)->E1_NUM),8,"0")
		cBco	:= AllTrim((cAliasTmp)->A6_AGENCIA) + AllTrim((cAliasTmp)->A6_NUMCON)
		cDV		:= FINX999M10(cBco+cAux+cNum)
		cRet	:= cAux+cNum+cDV

	Case cBanco == "104" //Caixa Economica Federal
	
		cAux	:= "82" //Número Fornecido pelo Banco
		cNum	:= PadL(AllTrim((cAliasTmp)->E1_NUM),8,"0")
		cDV		:= FINX999M11(cAux+cNum,2,cBanco)
		
		cRet	:= cAux+cNum+cDV
		
	Case cBanco == "399" //HSBC
	
		cNum	:= PadL(AllTrim((cAliasTmp)->E1_NUM),13,"0")
		cDV		:= FINX999M11(cNum,2,cBanco)

		cRet	:= cNum+cDV 
	
		//Complemento do N. Numero
		cAux	:= Str(Day((cAliasTmp)->E1_VENCREA))+Str(Month((cAliasTmp)->E1_VENCREA))+PadR(Year((cAliasTmp)->E1_VENCREA),2)
		cDV 	:= FINX999M11(cNum+cDV+(cAliasTmp)->A6_NUMCON+cAux,2,cBanco)
		
		cRet	+= "4"+cDV
	
	Case cBanco == "033" //Santander
	
		cNum	:= PadL(AllTrim((cAliasTmp)->E1_NUM),12,"0")
		cDV		:= FINX999M11(cNum,2,cBanco)
		
		cRet	:= cNum+cDV

	Case cBanco == "001" //Banco do Brasil
	
		cAux	:= "9999" //Número Fornecido pelo Banco
		cNum	:= PadL(AllTrim((cAliasTmp)->E1_NUM),7,"0")
		If lDV
			cDV	:= FINX999M11(cAux+cNum,2,cBanco)
		EndIf
		
		cRet	:= cAux+cNum+cDV	
EndCase
	
Return cRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999CpL
Geração valor do "Campo Livre" para alguns bancos

@author    TOTVS
@version   11.90
@since     04/09/13

@param	cAliasTmp	- Alias da tabela temporária

@return cRet 		- Cod. do Campo Livre
/*/
//------------------------------------------------------------------------------------------
Static Function FINX999CpL(cAliasTmp)
Local cBanco 	:= "" 
Local cRet 	:= ""

DEFAULT cAliasTmp := ""

cBanco := (cAliasTmp)->A6_COD

Do Case
	Case cBanco == "237" //Bradesco
		
		cRet := "" 
		cRet += PadL((cAliasTmp)->A6_AGENCIA,4,"0") 	//Agencia
		cRet += "22" 										//Carteira
		cRet += FINX999NN(cAliasTmp)						//Nosso Numero
		cRet += PadL((cAliasTmp)->A6_NUMCON,7,"0") 	//Conta
		cRet += "0"										//Constante Zero
		
	Case cBanco == "104" //Caixa Economica Federal
	
		cRet := ""
		cRet += "82"										   //Carteira
		cRet += PadL(AllTrim((cAliasTmp)->E1_NUM),8,"0") //Nosso Numero
		cRet += PadL((cAliasTmp)->A6_AGENCIA,4,"0")	   //Agencia
		cRet += "003"										   //Tipo de conta forn. pelo banco	
		cRet += PadL((cAliasTmp)->A6_NUMCON,8,"0")       //Conta
			
	Case cBanco == "001" //Banco do Brasil
	
		cRet := "" 
		cRet += FINX999NN(cAliasTmp,.F.)				//Nosso Numero sem DV
		cRet += PadL((cAliasTmp)->A6_AGENCIA,4,"0") 	//Agencia
		cRet += PadL((cAliasTmp)->A6_NUMCON,8,"0") 	//Conta
		cRet += "99"										//Tipo de Carteira forn. pelo banco 	
		
EndCase

Return cRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999M10

Cálculo do módulo 10

	 ----------------------------------------------------------------------------------- 
	|	Cálculo:																		|
	|																					|	
	|	1) 	Multiplica-se cada algarismo (nFator) pela sequencia de						| 
	|			multiplicadores (nMult) 2 e 1, da direita para a esquerda.				|
	|			Ex.: 	0	1	2	3	4	5											|
	|					|	|	|	|	|	|											|
	|					X	X	X	X	X	X											|
	|					|	|	|	|	|	|											|
	|					1	2	1	2	1	2 <--										|
	|					-------------------												|
	|					0	1	2	6	8	10											|
	|																					|
	|	2) 	Nos resultados em que o valor form maior que 9, soma-se os 					|
	|		dígitos:																	|
	|																					|
	|		Ex.:	0	1	2	6	8	10												|
	|				--------------------												|
	|				0	1	2	6	8	1												|
	|																					|
	|	3) Soma-se os valores para obter N (nSoma)										|
	|																					|
	|		Ex.:	0 + 1 + 2 + 6 + 8 + 1 = 18											|
	|																					|
	|	4) O Resto da divisão de N por 10 é subtraído de 10 para obter o DV.			|
	|																					|
	|			Ex.: 	18/10 	= 1 (resta 8)											|
	|					10 - 8	= 2														|
	|																					|
	|					DV = 2															|
	|																					|
	 -----------------------------------------------------------------------------------

@author    TOTVS
@version   11.90
@since     30/08/13

@param 		cBase	- Cadeia de algarismos base

@return	cRet 	- Dígito Verificador
/*/
//------------------------------------------------------------------------------------------
Static Function FINX999M10(cBase)
Local cAux		:= ""
Local cRet		:= ""
Local nX		:= 0
Local nMult	:= 0
Local nFator	:= 0
Local nSoma	:= 0
Local nResult	:= 0

DEFAULT cBase 		:= ""

nMult 	:= 1 //o multiplicador base inicia com 2,nMult inicia com 1 para que no primeiro laço fique com 2

For nX := Len(cBase) to 1 step -1
	//Algarismo
	nFator := Val(SubStr(cBase,nX,1))
	
	//Multiplicador 
	If nMult > 1
		nMult-- //(1)
	Else
		nMult++ //(2)
	EndIf

	//Resultado da Multiplicação
	cAux  := StrZero(nFator * nMult,2)
	nSoma += (Val(Left(cAux,1)) + Val(Right(cAux,1)))
	
Next nX

//Modulo 10
nResult := Mod(nSoma,10)

If nResult == 10 		//Resultado 10 --> DV = 0
	nResult := 0	
ElseIf nResult > 0 	//Resultado > 0 --> DV = 10 - Mod(10)
	nResult := 10 - nResult
EndIf

cRet := Str(nResult,1)

Return cRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999M11

Cálculo do módulo 11

	 ----------------------------------------------------------------------------------- 
	|	Cálculo:																		|
	|																					|	
	|	1) 	Multiplica-se cada algarismo (nFator) pela sequencia de						| 
	|		multiplicadores (nMult) 9 a 2, por exemplo, da direita para a esquerda.		|
	|			Ex.: 	0	1	2	3	4	5											|
	|					|	|	|	|	|	|											|
	|					X	X	X	X	X	X											|
	|					|	|	|	|	|	|											|
	|					4	5	6	7	8	9 <--										|
	|					----------------------											|
	|					0	5	12	21	32	45											|
	|																					|
	|	2) 	Nos resultados em que o valor form maior que 9, soma-se os 					|
	|		dígitos:																	|
	|																					|
	|		Ex.:	0	5	12	21	32	45												|
	|				----------------------												|
	|				0	5	3	3	5	9												|
	|																					|
	|	3) Soma-se os valores para obter N (nSoma)										|
	|																					|
	|		Ex.:	0 + 5 + 3 + 3 + 5 + 9 = 25											|
	|																					|
	|	4) 	Para o calculo do Dígito Verificador, cada banco possui uma regra a partir	|
	|		do resto da divisão do fator N por 11.										|
	|																					|
	 -----------------------------------------------------------------------------------

@author    TOTVS
@version   11.90
@since     30/08/13

@param 		cBase	- Cadeia de algarismos base
@param 		nOper	- Operação 1 (Codigo de Barras) e 2 (Nosso Numero e outros)
@param 		cBanco	- Cod. Banco

@return	cRet 	- Dígito Verificador
/*/
//------------------------------------------------------------------------------------------
Static Function FINX999M11(cBase,nOper,cBanco)
Local cRet	:= ""
Local aNumAux := Array(Len(cBase),3) //array com o conteudo do cNum para ser multiplicado
Local aLisMult:= {9,8,7,6,5,4,3,2} //Array/Lista de Multiplicadores
Local nResto    
Local nX 		:= 0
Local nSoma   	:= 0
Local nResult 	:= 0
Local nPos		:= 0

DEFAULT cBase	:= ""
DEFAULT cBanco	:= ""
DEFAULT nOper 	:= 0

//nOper = 	1 (Codigo de Barras)
//			2 (Nosso Numero e outros)			

//Multiplicadores
If cBanco == "237"
	aLisMult:= {7,6,5,4,3,2} //Bradesco utiliza base 7
Else
	aLisMult:= {9,8,7,6,5,4,3,2} //Outros Bancos utilizam base 9
EndIf

nPos := Len(aLisMult)

For nX := Len(cBase) to 1 step -1
	
	//Algarismo
	aNumAux[nX,1] := Val(SubStr(cBase,nX,1))
	
	//Multiplicador
	aNumAux[nX,2] := aLisMult[nPos]
	nPos--
	If nPos == 0
		nPos := Len(aLisMult)
	EndIf
	
	//Fator N
	aNumAux[nX,3] := aNumAux[nX,2] * aNumAux[nX,1]
	nSoma += aNumAux[nX,3]
Next

nResto := Mod(nSoma,11)

If nOper == 1
	
	nResult := 11 - nResto
	
	Do Case
		Case cBanco == "001" //Banco do Brasil
			
			If nResult == 0 .Or. nResult == 10 .Or. nResult == 11
				nResult := 1
			EndIf
		
		Case cBanco == "237" //Bradesco
			
			If nResult == 0 .Or. nResult == 1 .Or. nResult > 9
				nResult := 1
			EndIf
			
		Case cBanco == "104" //Caixa Economica Federal
			
			If nResult > 9
				nResult := 0
			EndIf
			
		Case cBanco == "399" //HSBC
			
			If nResult == 0 .Or. nResult == 1 .Or. nResult == 10
				nResult := 1
			EndIf
			
		Case cBanco == "341" //Itaú
			
			If nResult == 0 .Or. nResult == 0 .Or. nResult == 10 .Or. nResult == 11
				nResult := 1
			EndIf
			
		Case cBanco == "033" //Santander
				
			If nResult == 0 .Or. nResult == 10
				nResult := 1
			EndIf	
	
	EndCase
	
	cRet := Str(nResult,1)
	
ElseIf nOper == 2 //Nosso numero e outros

	Do Case
		
		Case cBanco == "001" //Banco do Brasil
			
			If nResto < 10
				nResult := nResto
				cRet := Str(nResult,1)	
			ElseIf nResto == 10
				cRet := "X"
			EndIf
		
		Case cBanco == "237" //Bradesco
		
			If nResto == 0
				nResult := 0		
			ElseIf nResto == 1
				cRet := "P"
			Else
				nResult := 11 - nResto
				cRet := Str(nResult,1)	
			EndIf
		
		Case cBanco == "104" //Caixa Economica Federal
			
			If nResto > 9
				nResult := 0	
			Else
				nResult := nResto	
			EndIf		
			
			cRet := Str(nResult,1)
			
		Case cBanco == "399" //HSBC
			
			If nResto == 0 .Or. nResto == 10
				nResult := 0	
			Else
				nResult := nResto
			EndIf
			
			cRet := Str(nResult,1)
			
		Case cBanco == "033" //Santander
			
			If nResto == 10
				nResult := 1	
			ElseIf nResto == 0 .Or. nResto == 1
				nResult := 0		
			Else
				nResult := 11 - nResto	
			EndIf
	
			cRet := Str(nResult,1)
	
	EndCase
	
EndIf

Return cRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999NCB
Geração o cálculo do código de barras

@author    TOTVS
@version   11.90
@since     04/09/13

@param	cAliasTmp	- Alias da tabela temporária

@return cRet 		- Código de Barras
/*/
//------------------------------------------------------------------------------------------
Static Function FINX999NCB(cAliasTmp)

Local cBlk1	:= ""
Local cBlk2	:= ""
Local cDV		:= ""
Local cCB 		:= ""
Local cBanco	:= ""
Local cAuxKey	:= ""
Local cCpoAux	:= ""
Local nVlrAbat	:= ""
Local cDvConta	:= ""

DEFAULT cAliasTmp := ""

cBanco 		:= (cAliasTmp)->A6_COD
nVlrAbat 	:= SomaAbat((cAliasTmp)->E1_PREFIXO,(cAliasTmp)->E1_NUM,(cAliasTmp)->E1_PARCELA,"R",1,dDataBase,(cAliasTmp)->A1_COD,(cAliasTmp)->A1_LOJA)

If Empty(AllTrim((cAliasTmp)->A6_DVCTA))
	cDvConta := FINX999M10(AllTrim((cAliasTmp)->A6_AGENCIA) + AllTrim((cAliasTmp)->A6_NUMCON))
Else
	cDvConta := AllTrim((cAliasTmp)->A6_DVCTA)
EndIf

Do Case
	Case cBanco $ "001|104|237" //Caixa Economica Federal/Banco do Brasil/Bradesco
		
		cCpoAux := FINX999CpL(cAliasTmp)	
		
		//Bloco 1
		cBlk1 := ""
		cBlk1 += cBanco 														//Banco
		cBlk1 += "9"															//Moeda
		
		//Bloco 2
		cBlk2 := ""
		cBlk2 += StrZero((cAliasTmp)->E1_VENCTO-CtoD("07/10/97"),4) 	//Vencimento
		cBlk2 += StrZero(((cAliasTmp)->E1_SALDO - nVlrAbat)*100,10)		//Valor
		cBlk2 += cCpoAux														//Campo Livre
		
	Case cBanco == "399" //HSBC
		
		cCpoAux := FINX999NN(cAliasTmp,.F.) //N. Numero sem DV
		
		//Bloco 1
		cBlk1 := ""
		cBlk1 += cBanco 																			//Banco
		cBlk1 += "9"																				//Moeda
		
		//Bloco 2
		cBlk2 := ""
		cBlk2 += StrZero((cAliasTmp)->E1_VENCTO-CtoD("07/10/97"),4) 						//Vencimento
		cBlk2 += StrZero(((cAliasTmp)->E1_SALDO - nVlrAbat)*100,10)							//Valor
		cBlk2 += PadR(AllTrim((cAliasTmp)->A6_NUMCON),7)										//Conta
		cBlk2 += cCpoAux 																			//N. Numero sem DV 
		AuxKey := "01/01/"+Str(Year((cAliasTmp)->E1_VENCTO))
		cBlk2 += StrZero((cAliasTmp)->E1_VENCTO-CtoD(cAuxKey),3) 	 						//Vencimento em formato Juliano															//Fixo 000	
		cBlk2 += SubStr(AllTrim(Str(Year((cAliasTmp)->E1_VENCTO))),4,1)						//Ultimo digito do ano (comp. Jul.)
		cBlk2 += "2"																				//Cod. Produto forn. pelo banco
		
	Case cBanco == "341" //Itaú

		cCpoAux := FINX999NN(cAliasTmp)

		//Bloco 1
		cBlk1 := ""
		cBlk1 += cBanco 																//Banco
		cBlk1 += "9"																	//Moeda
		
		//Bloco 2
		cBlk2 := ""
		cBlk2 += StrZero((cAliasTmp)->E1_VENCTO-CtoD("07/10/97"),4) 				//Vencimento
		cBlk2 += StrZero(((cAliasTmp)->E1_SALDO - nVlrAbat)*100,10)					//Valor
		cBlk2 += cCpoAux															//Carteira + Nosso número + DAC [Agência /Conta/Carteira/Nosso Número] 
		cBlk2 += PadR(AllTrim((cAliasTmp)->A6_AGENCIA),4)							//Agencia
		cBlk2 += PadR(AllTrim((cAliasTmp)->A6_NUMCON),5)							//Conta
		cBlk2 += cDvConta															//DV 
		cBlk2 += "000"														    	//Fixo 000	
		
	Case cBanco == "033" //Santander

		cCpoAux := FINX999NN(cAliasTmp)
		
		//Bloco 1
		cBlk1 := ""
		cBlk1 += cBanco 																//Banco
		cBlk1 += "9"																	//Moeda
		
		//Bloco 2
		cBlk2 := ""
		cBlk2 += StrZero((cAliasTmp)->E1_VENCTO-CtoD("07/10/97"),4) 			//Vencimento
		cBlk2 += StrZero(((cAliasTmp)->E1_SALDO - nVlrAbat)*100,10)				//Valor
		cBlk2 += "9"																	//Fixo 9
		cBlk2 += PadR(AllTrim((cAliasTmp)->A6_NUMCON),7)							//Conta
		cBlk2 += cCpoAux 																//N. Numero
		cBlk2 += "0"																	//IOS Seguradoras (7 a 9 ou 0)
		cBlk2 += "102"																	//Carteira forn. pelo banco
					
EndCase

//Digito Verificado Mod. 11
cDV := FINX999M11(cBlk1+cBlk2,1,cBanco)

//Cod. Barras
cCB := cBlk1+cDV+cBlk2

Return cCB

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999LDg
Geração da linha digitavel do boleto

@author    TOTVS
@version   11.90
@since     04/09/13

@param	cAliasTmp	- Alias da tabela temporária

@return cRet 		- String da Linha Digitável
/*/
//------------------------------------------------------------------------------------------
Static Function FINX999LDg(cAliasTmp)

Local cAuxKey	:= ""
Local cBanco  := ""
Local cCpoAux	:= ""
Local cCampo1 := ""
Local cCampo2 := ""
Local cCampo3 := ""
Local cCampo4 := ""
Local cCampo5 := ""
Local cCodBar	:= ""
Local cRet		:= ""
Local nVlrAbat	:= 0
Local cDvConta	:= ""

If Empty(AllTrim((cAliasTmp)->A6_DVCTA))
	cDvConta := FINX999M10(AllTrim((cAliasTmp)->A6_AGENCIA) + AllTrim((cAliasTmp)->A6_NUMCON))
Else
	cDvConta := AllTrim((cAliasTmp)->A6_DVCTA)
EndIf

cBanco := (cAliasTmp)->A6_COD

cCodBar := FINX999NCB(cAliasTmp)

Do Case
	Case cBanco == "001" //Banco do Brasil
		
		cCpoAux := cCodBar
		
		//Campo 1
		cCampo1 += cBanco									//Banco
		cCampo1 += "9"										//Moeda
		cCampo1 += SubStr(cCpoAux,20,5)					//Cod. Barra 20-24
		cCampo1 += FINX999M10(cCampo1)					//DV	
		
		//Campo 2
		cCampo2 += SubStr(cCpoAux,25,10)				//Cod. Barra 25-34
		cCampo2 += FINX999M10(cCampo2)					//DV
				
		//Campo 3
		cCampo3 += SubStr(cCpoAux,35,10)				//Cod. Barra 35-44
		cCampo3 += FINX999M10(cCampo3)					//DV
		
	
	Case cBanco == "237" //Bradesco
		
		cCpoAux := FINX999CpL(cAliasTmp)
		
		//Campo 1
		cCampo1 += cBanco									//Banco
		cCampo1 += "9"										//Moeda
		cCampo1 += SubStr(cCpoAux,1,5)					//Campo Livre 1-5
		cCampo1 += FINX999M10(cCampo1)					//DV	
		
		//Campo 2
		cCampo2 += SubStr(cCpoAux,6,10)				 	//Campo Livre 6-15
		cCampo2 += FINX999M10(cCampo2)					//DV
				
		//Campo 3
		cCampo3 += SubStr(cCpoAux,16,10)				 //Campo Livre 16-25
		cCampo3 += FINX999M10(cCampo3)					//DV		
		
	Case cBanco == "104" //Caixa Economica Federal
		
		cCpoAux := FINX999CpL(cAliasTmp)
		
		//Campo 1
		cCampo1 += cBanco						//Banco
		cCampo1 += "9"							//Moeda
		cCampo1 += SubStr(cCpoAux,1,5)		//Nosso Numero 1-5
		cCampo1 += FINX999M10(cCampo1)		//DV	
		
		//Campo 2
		cCampo2 += SubStr(cCpoAux,6,10)		//Campo Livre 6-15
		cCampo2 += FINX999M10(cCampo2)		//DV
				
		//Campo 3
		cCampo3 += SubStr(cCpoAux,16,10)	//Campo Livre 16-25
		cCampo3 += FINX999M10(cCampo3)		//DV	

	Case cBanco == "399" //HSBC
		
		cCpoAux := FINX999NN(cAliasTmp)
		
		//Campo 1 
		cCampo1 += cBanco																				//Banco
		cCampo1 += "9"																					//Moeda
		cCampo1 += PadL(SubStr((cAliasTmp)->A6_NUMCON,1,5),5,"0")								//Conta 1-5
		cCampo1 += FINX999M10(cCampo1)																//DV	
		
		//Campo 2
		cCampo2 += PadL(SubStr((cAliasTmp)->A6_NUMCON,6,2),2,"0")								//Conta 6-7
		cCampo2 += SubStr(cCpoAux,1,8)																//N.Numero 1-8
		cCampo2 += FINX999M10(cCampo2)																//DV
				
		//Campo 3
		cCampo3 += SubStr(cCpoAux,9,5)																//N.Numero 9-13
		cAuxKey := "01/01/"+AllTrim(Str(Year((cAliasTmp)->E1_VENCTO)))
		cCampo3 += StrZero((cAliasTmp)->E1_VENCTO-CtoD(cAuxKey),3)								//Vencimento em formato Juliano
		cCampo3 += SubStr(AllTrim(Str(Year((cAliasTmp)->E1_VENCTO))),4,1)						//Ultimo digito do ano (comp. Jul.)
		cCampo3 += "2"																					//Codigo do Produto for. pelo banco	
		cCampo3 += FINX999M10(cCampo3)																//DV		
		
	Case cBanco == "341" //Itaú
		
		cCpoAux := FINX999NN(cAliasTmp)
		
		//Campo 1 (AAABC.CCDDX):
		cCampo1 += cBanco										//AAA =	Código do Banco na Câmara de Compensação “341”
		cCampo1 += "9"											//B =	Código da moeda "9" (*)
		cCampo1 += "110"										//CCC =	Código da carteira de cobrança
		cCampo1 += SubStr(cCpoAux,4,2)							//DD = Nosso Numero 1-2 DD =	Os 2 primeiros dígitos
		cCampo1 += FINX999M10(cCampo1)							//X =	DAC que amarra o campo 1 (Anexo 3)DV
		
		//Campo 2
		cAuxKey := ""
		cAuxKey += AllTrim((cAliasTmp)->A6_AGENCIA)									//Agencia
		cAuxKey += AllTrim((cAliasTmp)->A6_NUMCON)									//Conta
		cAuxKey += "110" + PadL(AllTrim((cAliasTmp)->E1_NUM),8,"0")					//Carteira + Nosso Numero
																													
		//Campo 2 (DDDDD.DEFFFY)
		cCampo2 += SubStr(cCpoAux,6,6)											//DDDDDD =	O restante do Nosso Número (sem o DAC)
		cCampo2 += FINX999M10(cAuxKey)											//E = 	DAC do campo [ Agência/Conta/Carteira/ Nosso Número ]
		cCampo2 += PadL(SubStr((cAliasTmp)->A6_AGENCIA,1,3),3,"0")				//FFF =	Três primeiros números que identificam a Agência
		cCampo2 += FINX999M10(cCampo2)											// Y =	DAC que amarra o campo 2 (Anexo 3)	
		
		//Campo 3 (FGGGG.GGHHHZ) 
		cCampo3 += PadL(AllTrim(SubStr((cAliasTmp)->A6_AGENCIA,4,1)),1,"0")													//F =	Restante do número que identifica a agência
		cCampo3 += PadL(AllTrim(SubStr((cAliasTmp)->A6_NUMCON,1,5)),5,"0")	+ cDvConta									 	//GGGGGG =	Número da conta corrente +  DAC
		cCampo3 += "000"																									//HHH =	Zeros ( Não utilizado )
		cCampo3 += FINX999M10(cCampo3)	

	Case cBanco == "033" //Santander
			
		cCpoAux := FINX999NN(cAliasTmp)
		
		//Campo 1
		cCampo1 += cBanco															//Banco
		cCampo1 += "9"																//Moeda
		cCampo1 += "9"																//Valor Fixo = 9
		cCampo1 += PadL(SubStr(AllTrim((cAliasTmp)->A6_NUMCON),1,4),4,"0")	//Conta 1-4
		cCampo1 += FINX999M10(cCampo1)											//DV	
		
		//Campo 2
		cCampo2 += PadL(SubStr(AllTrim((cAliasTmp)->A6_NUMCON),5,3),3,"0")	//Conta 5-7
		cCampo2 += SubStr(cCpoAux,1,7)											//N.Numero 1-7
		cCampo2 += FINX999M10(cCampo2)											//DV
				
		//Campo 3
		cCampo3 += SubStr(cCpoAux,8,5)											//N.Numero 8-13
		cCampo3 += "0" 															//IOS
		cCampo3 += "102"															//Mod. da Carteira for. pelo banco	
		cCampo3 += FINX999M10(cCampo3)											//DV

EndCase

//Campo 1
cCampo1 := Transform(cCampo1,"@R 99999.99999")

//Campo 2
cCampo2 := Transform(cCampo2,"@R 99999.999999")

//Campo 3
cCampo3 := Transform(cCampo3,"@R 99999.999999")

//Campo 4
cCampo4 := SubStr(cCodBar,5,1) //K =	DAC do Código de Barras 

//Campo 5
nVlrAbat := SomaAbat((cAliasTmp)->E1_PREFIXO,(cAliasTmp)->E1_NUM,(cAliasTmp)->E1_PARCELA,"R",1,dDataBase,(cAliasTmp)->A1_COD,(cAliasTmp)->A1_LOJA)

cCampo5 += StrZero((cAliasTmp)->E1_VENCTO-CtoD("07/10/97"),4)
cCampo5 += StrZero(((cAliasTmp)->E1_SALDO - nVlrAbat)*100,10)

cRet := cCampo1 + "  " + cCampo2 + "  " + cCampo3 + "  " + cCampo4 + "  " + cCampo5 

Return cRet

//------------------------------------------------------------------------------------------
/*/{Protheus.doc} FINX999PRG
Perguntas do relatório

@author    TOTVS
@version   12.1.17
@since     20/12/2018
/*/
//------------------------------------------------------------------------------------------
static function FINX999PRG()

Local aParam		:= {}
Local lOk			:= .F.
Local nTamGrp001	:= TamSXG("001")[1]
Local nTamGrp002	:= TamSXG("002")[1]
Local nTamGrp007	:= TamSXG("007")[1]
Local nTamGrp011	:= TamSXG("011")[1]
Local nTamGrp018	:= TamSXG("018")[1]
Local cTitulo		:= "Impressão de boletos - Perguntas"


	aParam := {	{ 1 ,"Do prefixo"			,Space(3) 					,"@!" 	,""  ,"" 	,".T." ,3 ,.F. },; 
				{ 1 ,"Até o prefixo"		,PADR("",3,"Z")				,"@!" 	,""  ,"" 	,".T." ,3 ,.F. },;
				{ 1 ,"Do número"			,Space(nTamGrp018)			,"@!" 	,""  ,"" 	,".T." ,nTamGrp018 ,.F. },; 
				{ 1 ,"Até o número"			,PADR("",nTamGrp018,"Z")	,"@!" 	,""  ,"" 	,".T." ,nTamGrp018 ,.F. },;
				{ 1 ,"Da parcela"			,Space(nTamGrp011)  		,"@!" 	,""  ,"" 	,".T." ,nTamGrp011 ,.F. },; 
				{ 1 ,"Até a parcela"		,PADR("",nTamGrp011,"Z")  	,"@!" 	,""  ,"" 	,".T." ,nTamGrp011 ,.F. },;
				{ 1 ,"Do cliente"			,Space(nTamGrp001)  		,"@!" 	,""  ,"SA1" ,".T." ,nTamGrp001 ,.F. },; 
				{ 1 ,"Até o cliente"		,PADR("",nTamGrp001,"Z")  	,"@!" 	,""  ,"SA1" ,".T." ,nTamGrp001 ,.F. },;
				{ 1 ,"Da loja"				,Space(nTamGrp002)  		,"@!" 	,""  ,"" 	,".T." ,nTamGrp002 ,.F. },; 
				{ 1 ,"Até a loja"			,PADR("",nTamGrp002,"Z") 	,"@!" 	,""  ,"" 	,".T." ,nTamGrp002 ,.F. },;
				{ 1 ,"Da emissão"			,ctod("//")					, 	 	,""  ,"" 	,".T." ,50 ,.F. },; 
				{ 1 ,"Até a emissão"		,ctod("//")					,		,""  ,"" 	,".T." ,50 ,.F. },;
				{ 1 ,"Do vencimento"		,ctod("//")					, 		,""  ,"" 	,".T." ,50,.F. },; 
				{ 1 ,"Até o vencimento"		,ctod("//")					, 		,""  ,"" 	,".T." ,50 ,.F. },;
				{ 1 ,"Do borderô"			,Space(6) 					,		,""  ,"" 	,".T." ,6 ,.F. },;
				{ 1 ,"Até o borderô"		,Space(6)  					,"@!" 	,""  ,"" 	,".T." ,6 ,.F. },;
				{ 1 ,"Portador"				,Space(nTamGrp007)  		,"@!" 	,""  ,"SA6"	,".T." ,nTamGrp007 ,.F. },;
				{ 1 ,"Situação do título"	,Space(1)  					,"@!" 	,""  ,"FRV" ,".T." ,1 ,.F. }}
	
	lOk := ParamBox(aParam,cTitulo)

Return (lOk)
