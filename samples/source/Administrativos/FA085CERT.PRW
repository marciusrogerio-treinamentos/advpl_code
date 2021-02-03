#INCLUDE "F085CERTIMP.ch"      
#INCLUDE "Protheus.ch"      



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  F085CERTIMP ºAutor  ³ Ana Paula Nascimento º Data ³ 26/09/10 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Certificado de IVA e IR do Paraguai							   ±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ SIGAFIN                                                    º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function FA085CERT(aCertImp,nValorOp)                                          
Local cTitulo	:= STR0001
Local aNfs	:= {}
Local cChave
Local oPrint  
Local lExiste := .F.
Local nValRet := 0 
Local nTotRet := 0  
Local aRets := {}   
Local nX := 0
Local nValMerc := 0
Local nValImp := 0
Local cFornece:=""
Local cLoja:=""
Local dEmisCert
Local cCert := ""
Local cAliq:= ""
Local cNumOp:= ""
Local cDescCon := ""
Local cConceito := ""
Local nValOP := 0
Local nBsImpo:= 0
Local nRetMes := 0
Local nRetAnt:= 0
Local nTotVMer := 0   
Local nTotImp :=0  
Local nI := 0   
Local nBasImp := 0
Local nTotBas := 0   
Local 	lInfOP:= .T.   
Local aImposto:= {} 

Local aDados := {}
Local aItens := {} 


oPrint	:= TMSPrinter():New( cTitulo )
oPrint:SetPortrait() //Retrato
//oPrint:SetLandscape() //Paisagem


DbSelectArea("SFE")
DbSetOrder(2)    

DbSeek(xFilial("SFE")+aCertImp[1][3])
cFornece:=SFE->FE_FORNECE
cLoja:=SFE->FE_LOJA
dEmisCert:=SFE->FE_EMISSAO 
nValRet := SFE->FE_RETENC
cCert := SFE->FE_NROCERT
cNumOp:= SFE->FE_ORDPAGO   
aRetenc:={} 

nPosNF:=0


While SFE->(!EOF() ).and. (xFilial("SFE")+cNumOp) ==(SFE->FE_FILIAL+SFE->FE_ORDPAGO)
	nTotRet += SFE->FE_RETENC 
	  
	  nPos:=AScan(aDados,{|x| x[1]== SFE->FE_SERIE .And. x[2]== SFE->FE_NFISCAL.And. x[3]== SFE->FE_PARCELA})	
	
      If Len(aDados) == 0 .Or. nPos == 0
	  	aItens := Array(4)
	    
	  	aItens[1] := SFE->FE_SERIE 
	  	aItens[2] := SFE->FE_NFISCAL
		aItens[3] := SFE->FE_PARCELA 
		
		aAdd(aImposto, {SFE->FE_TIPO,SFE->FE_ALIQ,SFE->FE_RETENC})
		aItens[4] := aImposto
		aAdd(aDados,aItens)
		aImposto:={}
		
	Else 
		aAdd(aDados[nPos][4], {SFE->FE_TIPO,SFE->FE_ALIQ,SFE->FE_RETENC})
	EndIf
    
    



	SFE->(DBSKIP())
EndDo    

cNumOp := SubStr(cNumOp,1,TamSX3("EK_ORDPAGO")[1])

	For nX:=1 to Len(aDados)
		nPos:= AScan(aDados[nX][4] , {  |x| x[1]  == "I" .Or. x[1]  == "R" }) 
	 	

	 
	 	IF aDados[nX][4][nPos][3] < 0
			DbSelectArea("SF2")
			DbSetOrder(1)
   			If DbSeek(xFilial("SF2")+aDados[nX][2]+aDados[nX][1]+cFornece+cLoja)
				nValMerc:= SF2->F2_VALMERC
				nTotVMer-= nValMerc   
				
				// Verifica qual o campo de impostos que esta sendo gravado o valor do IVA na nota
	  		 	aArea:=GetArea()
		  		dbSelectArea("SD2")
	   			SD2->(DbSetOrder(3))
			 	SD2->(DbSeek(xFilial("SD2")+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA))
			   	Do while SD2->( ! EoF() .And. xFilial("SD2") == D2_FILIAL .And. SF2->F2_DOC == D2_DOC .And. ;
								SF2->F2_SERIE == D2_SERIE .And. SF2->F2_CLIENTE == D2_CLIENTE .And. ;
								SF2->F2_LOJA == D2_LOJA )
				 	aImpInf := TesImpInf(SD2->D2_TES)
					For nI := 1 To Len(aImpInf) 
						If "IV"$Trim(aImpInf[nI][01])					
							nValImp += SD2->( FieldGet( FieldPos( aImpInf[nI][02] ) ) ) 
							nBasImp += SD2->( FieldGet( FieldPos( aImpInf[nI][07] ) ) )
						EndIf
					Next nI     
					SD2->( dbSkip() )										
				EndDo
				RestArea(aArea)
                                   

				nTotImp -= nValImp
				nTotBas -= nBasImp // Total de valor sem IVA
				nPosNf:=AScan(aDados,{|x| x[2]== SF2->F2_DOC .And. x[1]==SF2->F2_SERIE})
				Aadd(aDados[nX],nBasImp*-1)
				Aadd(aDados[nX],nValImp*-1) 
				aADD(aDados[nX],SF2->F2_ESPECIE) 
				aADD(aDados[nX],nValMerc)
				nValImp:=0
				nBasImp:=0
			EndIf
		Else
			DbSelectArea("SF1")
			DbSetOrder(1)
			If DbSeek(xFilial("SF1")+aDados[nX][2]+aDados[nX][1]+cFornece+cLoja)
				nValMerc:= SF1->F1_VALMERC 
				nTotVMer+= nValMerc
			
				// Verifica qual o campo de impostos que esta sendo gravado o valor do IVA na nota
			 	aArea:=GetArea()
		  		dbSelectArea("SD1")
	   			SD1->(DbSetOrder(1))
			 	SD1->(DbSeek(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))
			   	Do while SD1->( ! EoF() .And. xFilial("SD1") == D1_FILIAL .And. SF1->F1_DOC == D1_DOC .And. ;
								SF1->F1_SERIE == D1_SERIE .And. SF1->F1_FORNECE == D1_FORNECE .And. ;
								SF1->F1_LOJA == D1_LOJA )
				 	aImpInf := TesImpInf(SD1->D1_TES)
					For nI := 1 To Len(aImpInf) 
						If  "IV"$Trim(aImpInf[nI][01]).AND.aImpInf[nI][01]!="RIV" 
							nValImp += SD1->( FieldGet( FieldPos( aImpInf[nI][02] ) ) ) 
							nBasImp += SD1->( FieldGet( FieldPos( aImpInf[nI][07] ) ) )
						EndIf
					Next nI     
					SD1->( dbSkip() )										
				EndDo
				RestArea(aArea)

				nTotImp += nValImp
				nTotBas += nBasImp // Total de valor sem IVA
				nPosNf:=AScan(aDados,{|x| x[2]== SF1->F1_DOC .And. x[1]==SF1->F1_SERIE})
				Aadd(aDados[nX],nBasImp)
				Aadd(aDados[nX],nValImp) 
				aADD(aDados[nX],SF1->F1_ESPECIE)
				aADD(aDados[nX],nValMerc)
				
				nValImp:=0
				nBasImp:=0
				
			EndIf	
		EndIF
	Next nX

                     

PrintPag( oPrint,cFornece,cLoja,dEmisCert,cNumOp,aDados,nTotVMer,nTotBas,nTotImp,nValorOp)

oPrint:Preview()

Return


Static Function PrintPag( oPrint,cFornece,cLoja,dEmisCert,cNumOp,aDados,nTotVMer,nTotBas,nTotImp,nValorOp)

Local oFont1	:= TFont():New("Arial",15,15,,.T.,,,,.T.,.F.)
Local oFont2	:= TFont():New("Arial",11,11,,.F.,,,,.T.,.F.)
Local oFont3	:= TFont():New("Arial",09,09,,.T.,,,,.T.,.F.)
Local oFont4	:= TFont():New("Arial",10,10,,.F.,,,,.T.,.F.)
Local oFont5	:= TFont():New("Arial",10,10,,.T.,,,,.T.,.F.)
Local Ni:= 0  
Local nY := 0     
Local nTotIVA:=0
Local nTotIR := 0
Local cTimbrado := ""
Local dDtValTim := cTod("")   

dDataCert:=StrZero(Day(dEmisCert),2) + " " + STR0002 + " " + MesExtenso(Month(dEmisCert)) + " " + STR0002 + " "  + Alltrim(Str(Year(dEmisCert)))
SX5->(DbSeek(xFilial()+"12"+SM0->M0_ESTENT))
cProvEmp:=Alltrim(X5Descri())


oPrint:StartPage()

//Cabeçalho
oPrint:Box(0150,050,0450,1250)  

oPrint:Box(0150,1250,0450,2300)  

oPrint:Say(0170,0140,Alltrim(SM0->M0_NOMECOM),oFont1)
oPrint:Say(0325,0190,Alltrim(SM0->M0_ENDENT)+" - " + cProvEmp,oFont2)

oPrint:Say(0166,1550,STR0003 + cTimbrado,oFont2)
oPrint:Say(0215,1550,STR0004 + Dtoc(dDtValTim),oFont2)
oPrint:Say(0263,1550,STR0005,oFont3)
oPrint:Say(0260,1650,transf(SM0->M0_CGC,pesqpict("SA2","A2_CGC")),oFont3) 
oPrint:Say(0320,1485,STR0006,oFont3)
oPrint:Say(0390,1600,Transf(cNumOp,"@e 999-999-9999999") ,oFont3)



oPrint:box(0450,050,0565,2300) 	
oPrint:Say(0465,0100,STR0007,oFont4)
oPrint:Say(0465,0220,dDataCert,oFont4) 
oPrint:Line(0510,070,0510,2250)                                         

// Dados do Fornecedor
DbSelectArea("SA2")
DbSetOrder(1)
DbSeek(xFilial("SA2") + cFornece + cLoja)  
cNome:=SA2->A2_NOME
cCUITForn:=Transf(SA2->A2_CGC,pesqpict("SA2","A2_CGC"))
cEnd := SA2->A2_END

SX5->(DbSeek(xFilial()+"12"+SA2->A2_EST))
cProvForn:=Alltrim(X5Descri())


oPrint:Say(0520,0100,STR0008,oFont4)
oPrint:Say(0520,0805,cNome,oFont4)  

oPrint:Say(0520,1440,STR0009,oFont4)
oPrint:Say(0520,1940,cCUITForn,oFont4)	

// Colunas
oPrint:box(0565,050,0625,0450)   
oPrint:Say(0580,0150,STR0010,oFont4)

oPrint:box(0565,0450,0625,0750)           
oPrint:Say(0580,0490,STR0013,oFont4)

oPrint:box(0565,0750,0625,1050)                            
oPrint:Say(0580,0800,STR0011,oFont4) 

oPrint:box(0565,1050,0625,1350)          
oPrint:Say(0580,1070,STR0012,oFont4) 

oPrint:box(0565,1350,0625,1550)           
oPrint:Say(0580,1355,STR0014,oFont4)

oPrint:box(0565,1550,0625,1850)           
oPrint:Say(0580,1580,STR0015,oFont4)

oPrint:box(0565,1850,0625,2050)  
oPrint:Say(0580,1890,STR0017,oFont4)

oPrint:box(0565,2050,0625,2300)  
oPrint:Say(0580,2080,STR0018,oFont4)


nLin:=0625

For nI:= 1 To Len(aDados)    
	
	dbSelectArea("SX5")
	If dbSeek(cFilial+"05"+aDados[nI][7])
		#IFDEF ENGLISH
			cTipoDoc:= Alltrim(X5_DESCENG)
		#ELSE
			#IFDEF SPANISH
				cTipoDoc:= Alltrim(X5_DESCSPA)
			#ELSE
				cTipoDoc:= Alltrim(X5_DESCPOR)
			#ENDIF
		#ENDIF
    EndIf

	oPrint:box(nLin,050,nLin+69,0450) 
 	oPrint:box(nLin,0450,nLin+69,0750)
 	oPrint:box(nLin,0750,nLin+69,1050)
 	oPrint:box(nLin,1050,nLin+69,1350)
 	oPrint:box(nLin,1350,nLin+69,1550)
	oPrint:box(nLin,1550,nLin+69,1850)
	oPrint:box(nLin,1850,nLin+69,2050)
	oPrint:box(nLin,2050,nLin+69,2300)

	oPrint:Say( nLin+10,070,(SubStr(cTipoDoc,1,15)) + "-" +aDados[nI,2],oFont4) // Numero e Tipo de Titulo
	oPrint:Say( nLin+10,475,Transform(aDados[nI,8],"@E 999,999,999.99"),oFont4)	// Valor total da fatura
	oPrint:Say( nLin+10,750,Transform(aDados[nI,5],"@E 999,999,999.99"),oFont4)	// Valor Sem IVA
	oPrint:Say( nLin+10,1050,Transform(aDados[nI,6],"@E 999,999,999.99"),oFont4)	// Valor do IVA
	For nY:= 1 to Len(aDados[nI][4]) 
		If aDados[nI][4][nY][1] == "I"
			nTotIVA+=aDados[nI][4][nY][3]
			oPrint:Say( nLin+10,1350,Transform(aDados[nI,4,nY,2],"@E 999,999,999.99"),oFont4)	// Aliquota da retenção do IVA
			oPrint:Say( nLin+10,1535,Transform(aDados[nI,4,nY,3],"@E 999,999,999.99"),oFont4)	// Valor da retenção do IVA
		ElseIf aDados[nI][4][nY][1] == "R"
			nTotIR+=aDados[nI][4][nY][3]
			oPrint:Say( nLin+10,1780,Transform(aDados[nI,4,nY,2],"@E 999,999,999.99"),oFont4)	// Aliquota da retenção do IR
			oPrint:Say( nLin+10,2065,Transform(aDados[nI,4,nY,3],"@E 999,999,999.99"),oFont4)	// Valor da retenção do IR

		EndIf
		
			
	Next nY
	



    nLin+=69
Next 
   	oPrint:box(nLin,050,nLin+69,0450) 
 	oPrint:box(nLin,0450,nLin+69,0750)
 	oPrint:box(nLin,0750,nLin+69,1050)
 	oPrint:box(nLin,1050,nLin+69,1350)
 	oPrint:box(nLin,1350,nLin+69,1550)
	oPrint:box(nLin,1550,nLin+69,1850)
	oPrint:box(nLin,1850,nLin+69,2050)
	oPrint:box(nLin,2050,nLin+69,2300)
				
	oPrint:Say( nLin+10,070,STR0016,oFont5) // Serie
	oPrint:Say( nLin+10,0475,Transform(nTotVMer,"@E 999,999,999.99"),oFont5)	// Valor total da fatura
	oPrint:Say( nLin+10,0750,Transform(nTotBas,"@E 999,999,999.99"),oFont5)	// Valor sem iVa
	oPrint:Say( nLin+10,1060,Transform(nTotImp,"@E 999,999,999.99"),oFont5)	// VAlor do iva
	oPrint:Say( nLin+10,1550,Transform(nTotIVA,"@E 999,999,999.99"),oFont5)	// Valor do IVA
	oPrint:Say( nLin+10,2055,Transform(nTotIR,"@E 999,999,999.99"),oFont5)	// Valor do IR
	 nLin+=69
	oPrint:box(nLin,050,nLin+69,0450)               
	oPrint:Say( nLin+10,070,STR0019,oFont5) // Serie
 	oPrint:box(nLin,0450,nLin+69,2300)
	oPrint:Say( nLin+10,0470,Transform(nValorOp,"@E 999,999,999.99"),oFont5)	// Valor da OP
  
aCert:= {}

oPrint:EndPage()

Return
