#INCLUDE "protheus.ch"
#INCLUDE "report.ch" 
#INCLUDE "fwprintsetup.ch"

#DEFINE __RELIMP PLSMUDSIS(getWebDir() + getSkinPls() + "\relatorios\")
#DEFINE	 IMP_PDF 6 
#DEFINE	 TAM_A4 9	//A4     	210mm x 297mm  620 x 876		

//-------------------------------------------------------------------
/*/{Protheus.doc} PL99BCon

Monta estrutura do relatorio de atendimento Protocolos RN 395

@author  Equipe PLS
@version P11
@since   11/08/16
/*/
//------------------------------------------------------------------- 
User Function PL99BCon()
Local aDados     := paramixb[1]  
Local lImpEmail  := paramixb[2]  
Local lPortalWeb := paramixb[3]
Local lSrvUnix   := IsSrvUnix()

Local oFontCab   := TFont():New("Arial", 20, 20, , .T., , , , .T., .F.)  
Local oFontNorm	 := TFont():New("Arial", 14, 14, , .F., , , , .T., .F.)   
Local oFontUnder := TFont():New("Arial", 14, 14, , .T., , , , .T., .F.,.T.)        
Local oFontBenNe := TFont():New("Arial", 14, 14, , .T., , , , .T., .F.)  

LOCAL cFileName := ""
Local cFolder   := GetNewPar("MV_P412PDF","")    
LOCAL cTexto    := ""
Local cPathSrv  := GetNewPar("MV_PLDIDOT", "\dot\" ) 
Local nHeiPag   := 2200                              	
Local nLin      := nHeiPag
Local nX      	:= 0
Local nY        := 0
LOCAL lDisSetup := .T.
LOCAL lOk       := .T.
LOCAL aValorPend:= {}
Private oPrn       
/*ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Dados do Array aDados                                                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aDados[01] -> Municipio Operadora
aDados[02] -> UF Municipio Operadora      
aDados[03] -> Data Impressao
aDados[04] -> Nome Beneficiario  
aDados[05] -> Data Atendimento/Protocolo
aDados[06] -> CPF
aDados[07] -> Matricula Beneficiario
aDados[08] -> Telefone Central
aDados[09] -> Nome Operadora
aDados[10] -> Numero Protocolo
aDados[11] -> Observacao (somente Guias de Atendimento)
aDados[12] -> Ocorrencia Call Center
aDados[13] -> Solucao Call Center
*/       

If Empty(cFolder) .And. !lPortalWeb
	cFolder := PLSMUDSIS(GetTempPath()+"totvsprinter\") 
EndIf

If lImpEmail .And. Empty(B5J->B5J_EMAIL)                        
	lDisSetup := .F.
EndIf

cFileName := lower("concan_"+aDados[10]+".pdf")     

If lPortalWeb
	cPathSrv := __RELIMP
ElseIf !Substr(cPathSrv,len(cPathSrv),1) $ "\/"     
	cPathSrv := PLSMUDSIS(cPathSrv + "\")
EndIf
                              
nH   := PLSAbreSem("PL99BRSMF.SMF")
oPrn := FWMSPrinter():New(cFileName,IMP_PDF,.T.,cPathSrv,lDisSetup,.F.,@oPrn,,.T.,.F.,.F.,.T.)
PLSFechaSem(nH,"PL99BRSMF.SMF")

nCol1 	   :=  040 // Margem da coluna
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Resolucao do relatorio                                                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oPrn:setResolution(72)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Modo retrato                                                                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oPrn:setPortrait()
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Papel A4                                                                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oPrn:setPaperSize(TAM_A4)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Margem                                                                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oPrn:setMargin(100,100,100,100) 
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Imprime cabecalho                                                                             ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
nLin := FS_CabecImp(@oPrn, aDados)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Mensagem principal do corpo                                                                   ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ     
nLin += 110
oPrn:Say(nLin, nCol1, "Ao Solicitante,", oFontNorm)
nLin += 070
oPrn:Say(nLin, nCol1, aDados[04], oFontNorm)
nLin += 180                                                  
oPrn:Say(nLin, nCol1+470, "Confirmação de Cancelamento de Plano", oFontCab)       
nLin += 180 
oPrn:Say(nLin, nCol1, "Prezado,", oFontNorm)  
nLin += 070
oPrn:Say(nLin, nCol1, "Conforme solicitação realizada em  "+aDados[05]+" por ", oFontNorm)  
oPrn:Say(nLin, nCol1+0950 , aDados[04], oFontUnder)

nLin += 050  
oPrn:Say(nLin, nCol1 , "inscrito(a) no CPF "+aDados[06]+", os beneficiários abaixo tiveram o contrato rescindido no dia "+aDados[05]+":", oFontNorm)  
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Imprime beneficiarios                        	                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ 
If len(aDados) > 0   
	nLin += 050 
	For nX := 1 to len(aDados[12]) 
		For nY:= 1 to len(aDados[12][nX])
	    	nLin += 050           
	    	nLin := FS_EndPage(nLin,oPrn,aDados)
	    	oPrn:Say(nLin, nCol1    , aDados[12][nX][nY][1], oFontBenNe)
			oPrn:Say(nLin, nCol1+330, aDados[12][nX][nY][2], oFontNorm )  
		Next
   		nLin += 070
	Next
EndIf  

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Busca titulos em aberto                        	                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aValorPend := valTitulos() 
If len(aValorPend) > 0 
	nLin += 110      
	oPrn:Say(nLin, nCol1, "Há valores de cobrança pendentes para esta família: ", oFontNorm)
	nLin += 050
	For nX := 1 to len(aValorPend) 
		For nY:= 1 to len(aValorPend[nX])
	    	nLin += 050   
	    	nLin := FS_EndPage(nLin,oPrn,aDados)
	    	oPrn:Say(nLin, nCol1    , aValorPend[nX][nY][1], oFontBenNe)
			oPrn:Say(nLin, nCol1+360, aValorPend[nX][nY][2], oFontNorm )  
		Next
   		nLin += 070
	Next
EndIf	
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Observacoes do Beneficiario                 	                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//nLin += 035
//nLin := impMemo(oPrn,nLin,Alltrim(aDados[11]),aDados)
 	
//nLin += 140
//oPrn:Say(nLin, nCol1, "Segue o nosso parecer para ocorrência(s) apresentada(s):", oFontNorm)    
//nLin += 035
//nLin := impMemo(oPrn,nLin,Alltrim(aDados[13]),aDados)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Finaliza relatorio                       	                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
nLin += 200  
If nLin >= 2850
	nLin := FS_EndPage(nLin,oPrn,aDados)
EndIf	
oPrn:Say(nLin, nCol1 , "Solicitamos, por gentileza, caso restem dúvidas, permanecemos à disposição através da nossa Central de Relacionamento com Cliente, ", oFontNorm)       
nLin += 070
oPrn:Say(nLin, nCol1 , "no número "+aDados[08]+".",oFontNorm)       
nLin += 140
oPrn:Say(nLin, nCol1 , "Atenciosamente,",oFontNorm) 
nLin += 070
oPrn:Say(nLin, nCol1 , aDados[09] , oFontUnder)    

nLin := 2850
oPrn:Say(nLin+070, 2000, "Página "+cValtoChar(oPrn:nPageCount) , oFontUnder) 
	
oPrn:SetViewPDF(.F.)
oPrn:lServer    := .T.    
oPrn:cPathPDF   := cPathSrv   
oPrn:cPathPrint := cPathSrv  
oPrn:setDevice(IMP_PDF)      
If lSrvUnix	
	ajusPath(@oPrn) 
EndIf	
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Deleta arquivo se ja existente  									        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
FERASE(PLSMUDSIS(cPathSrv)+cFileName) 
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Gera o relatorio   													        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ 
oPrn:Preview()    
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Abre arquivo PDF e deleta no server  								        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  
If !lPortalWeb
	FERASE( PLSMUDSIS(cFolder)+cFileName) //deleta o arquivo se ja existir
	Sleep(2000)
	lCopy := CpyS2T( PLSMUDSIS(cPathSrv)+cFileName, PLSMUDSIS(cFolder), .F. )  
	If lCopy .And. !lImpEmail
		Sleep(2000)
		shellExecute("Open", PLSMUDSIS(cFolder)+cFileName, " /k dir", PLSMUDSIS("c:\"), 1 )    
	ElseIf !lCopy
		Aviso( "Atenção" , "Não foi possível copiar o relatório gerado no servidor, entre em contato com o administrador do sistema." , {"Ok"} )
	EndIf	
	FERASE( PLSMUDSIS(cPathSrv)+cFileName) //deleta arquivo no servidor
EndIf

Return {lOk,cFolder,cFileName}
                              


//-------------------------------------------------------------------
/*/{Protheus.doc} FS_CabecImp

Imprime cabecalho do relatório da RN 395

@author  Equipe PLS
@version P11
@since   28/06/16
/*/
//-------------------------------------------------------------------   
Static Function FS_CabecImp(oPrn, aDados)
Local nMarSup	   :=  317   	             // Margem superior        
Local nCol1 	   :=  015		             // Margem da coluna1
Local oFontNeg	:= TFont():New("Arial", 16, 16, , .T., , , , .T., .F.)

nLin   := nMarSup     
oPrn:StartPage()     

oPrn:Say(nLin, nCol1, "Protocolo Nº "+ aDados[10], oFontNeg) 
nLin += 070
oPrn:Say(nLin, nCol1+1200, aDados[01]+"-"+aDados[02]+", "+aDados[3], oFontNeg)       
nLin += 140

Return(nLin)  
                       


//-------------------------------------------------------------------
/*/{Protheus.doc} FS_EndPage

Verifica quebra de pagina

@author  Equipe PLS
@version P11
@since   28/06/16
/*/
//-------------------------------------------------------------------   
Static Function FS_EndPage(nLin,oPrn,aDados)             
Local oFontUnder:= TFont():New("Arial", 14, 14, , .T., , , , .T., .F.,.T.)   

If nLin >= 2850
	oPrn:Say(nLin+070, 2000, "Página "+cValtoChar(oPrn:nPageCount) , oFontUnder)
	oPrn:EndPage()  
	nLin := FS_CabecImp(oPrn, aDados)
EndIf

Return nLin  



//-------------------------------------------------------------------
/*/{Protheus.doc} impMemo

Imprime um campo memo

@author  Equipe PLS
@version P11
@since   28/06/16
/*/
//-------------------------------------------------------------------   
Static Function impMemo(oPrn,nLin,cMemo,aDados,cFonte)
Local oFontObs	 := ""
Local aDadObs    := {}     
Local lLoop      := .T.
Local nTamLin    := 110//120     
Local nFor       := 0
Local nContBlank := 0	
Default cFonte   := "1"   

Do Case 
	Case cFonte == "0"//Normal            
    	oFontObs := TFont():New("Arial", 14, 14, , .F., , , , .T., .F.)     
    
    Case cFonte == "1"//Negrito
    	oFontObs := TFont():New("Arial", 14, 14, , .T., , , , .T., .F.)   
EndCase
   
While lLoop
	If len(cMemo) < nTamLin  
		If (nPosChr13 := At(Chr(13),Substr(cMemo,1,nTamLin))) < nTamLin .And. nPosChr13 <> 0  
			Aadd(aDadObs,Substr(cMemo,1,nPosChr13))  
			cMemo := Substr(cMemo,nPosChr13+1,len(cMemo)) 	
		Else	
			Aadd(aDadObs,cMemo)
			lLoop := .F.
		EndIf	
	Else
		If (nPosChr13 := At(Chr(13),Substr(cMemo,1,nTamLin))) < nTamLin .And. nPosChr13 <> 0 
			Aadd(aDadObs,Substr(cMemo,1,nPosChr13))  
			cMemo := Substr(cMemo,nPosChr13+1,len(cMemo)) 		
		Else            
			lBlank     := .F.  
			nContBlank := 0
			While !lBlank 
				If Substr(cMemo,nTamLin-nContBlank,1) == " "
		        	lBlank := .T.
		        Else
		        	nContBlank ++
		        EndIf
		    EndDo   
		    Aadd(aDadObs,Substr(cMemo,1,nTamLin-nContBlank))
			cMemo := Substr(cMemo,(nTamLin-nContBlank)+1,len(cMemo))   
		EndIf	
	EndIf
EndDo   
	
For nFor := 1 to len(aDadObs)     
   	nLin += 050        
   	nLin := FS_EndPage(nLin,oPrn,aDados)
   	aDadObs[nFor] := StrTran(aDadObs[nFor],Chr(10),"")
   	aDadObs[nFor] := StrTran(aDadObs[nFor],Chr(13),"")
   	oPrn:Say(nLin, nCol1+90, aDadObs[nFor] , oFontObs) 
Next

Return nLin    


//-------------------------------------------------------------------
/*/{Protheus.doc} AjusPath

Ajusta paths

@author  Equipe PLS
@version P11
@since   28/06/16
/*/
//-------------------------------------------------------------------  
Static Function AjusPath(oPrn)
oPrn:cFilePrint := StrTran(oPrn:cFilePrint,"\","/",1)
oPrn:cPathPrint := StrTran(oPrn:cPathPrint,"\","/",1)
oPrn:cFilePrint := StrTran(oPrn:cFilePrint,"//","/",1)
oPrn:cPathPrint := StrTran(oPrn:cPathPrint,"//","/",1)
Return



//-------------------------------------------------------------------
/*/{Protheus.doc} valTitulos

Busca os valores dos titulos em aberto 

@author  Equipe PLS
@version P11
@since   28/06/16
/*/
//-------------------------------------------------------------------  
Static Function valTitulos()
Local cMatric  := ""
Local aCliente := {}  
Local aDadFin  := {}
Local aAux     := {}
Local _cNivel  := ""
Local _cChave  := ""
Local cChvBBT  := ""

//Deve se remontar o matric para sempre ser pela matricula nova. Havia casos que vinha pela antiga e gerava problema
cMatric := BA1->(BA1_CODINT+BA1_CODEMP+BA1_MATRIC)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ A consulta ira considerar o nivel de cobranca agora, ao invez da matricula da familia.  |
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
aCliente := PLSRETNCB(BA1->BA1_CODINT,BA1->BA1_CODEMP,BA1->BA1_MATRIC,NIL)
If Len(aCliente) > 0 .and. aCliente[1]
	
	_cNivel := aCliente[5]
	If _cNivel == "1" // Empresa
		_cChave := BA3->BA3_CODINT+BA3->BA3_CODEMP
		cChvBBT := "BBT->(BBT_CODOPE+BBT_CODEMP)"
	Elseif _cNivel == "2" //Nivel contrato
		_cChave := BA3->BA3_CODINT+BA3->BA3_CODEMP+BA3->BA3_CONEMP+BA3->BA3_VERCON
		cChvBBT := "BBT->(BBT_CODOPE+BBT_CODEMP+BBT_CONEMP+BBT_VERCON)"
		
	Elseif _cNivel == "3"  //Nivel subcontrato
		_cChave := BA3->BA3_CODINT+BA3->BA3_CODEMP+BA3->BA3_CONEMP+BA3->BA3_VERCON+BA3->BA3_SUBCON+BA3->BA3_VERSUB
		cChvBBT := "BBT->(BBT_CODOPE+BBT_CODEMP+BBT_CONEMP+BBT_VERCON+BBT_SUBCON+BBT_VERSUB)"
		
	Elseif _cNivel == "4" //Nivel familia
		_cChave := BA3->BA3_CODINT+BA3->BA3_CODEMP+BA3->BA3_MATRIC
		cChvBBT := "BBT->(BBT_CODOPE+BBT_CODEMP+BBT_MATRIC)"
		
	Endif
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se houve faturas no mes... atualiza o valor do flag...     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	BBT->(DbSetOrder(Val(_cNivel)))
	If BBT->(MsSeek(xFilial("BBT")+_cNivel+_cChave))

		If ExistBlock( "PLSXFILI" )
			cSqlFilial := ExecBlock( "PLSXFILI", .F., .F., {"SE1"} )
		Else
			cSqlFilial := xFilial("SE1")
		EndIf 
		
		While ! BBT->(Eof()) .and. (_cNivel+&cChvBBT) == _cNivel+_cChave
			
			SE1->(DbSetOrder(1))
			If SE1->(MsSeek(cSqlFilial+BBT->BBT_PREFIX+BBT->BBT_NUMTIT+BBT->BBT_PARCEL+BBT->BBT_TIPTIT))
	
				// Monta matriz financeira...
				If SE1->E1_SALDO > 0 // Titulos em aberto.
					aAux := {}
					Aadd(aAux,{"Mês/Ano Cobrança:",SE1->E1_MESBASE+"/"+SE1->E1_ANOBASE })   
 					Aadd(aAux,{"Data de Vencimento:",Substr(Dtos(SE1->E1_VENCTO),7,2)+"/"+Substr(Dtos(SE1->E1_VENCTO),5,2)+"/"+Substr(Dtos(SE1->E1_VENCTO),1,4) })  
 					Aadd(aAux,{"Valor:","R$ "+Alltrim(Transform(SE1->E1_VALOR, "@E 999999.99"))  })
 					
				    Aadd(aDadFin,aAux)
				Endif
								                                    
			Endif
			
			BBT->( dbSkip() )
		Enddo
	Endif
Endif

Return aDadFin