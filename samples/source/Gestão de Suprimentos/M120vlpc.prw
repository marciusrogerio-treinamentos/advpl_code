#INCLUDE "PROTHEUS.CH"  

//-------------------------------------------------------------------
/*/{Protheus.doc} COMA120
Validacao dos pedidos de compra na pre-nota
/*/
//obs, tratamento para o CNI ..
//-------------------------------------------------------------------
User Function M120vlpc() 

Local lAtesto   := GETMV("MV_XATESTO") // parâmetro exclusivo CNI
Local nx        := 0  
Local cSeek     := ""  
Local cSolic    := "" 
Local cRequi    := ""
Local cxVer     := ""                                                    
Local lProb		:= .F.  
Local lRet		:= .T.
Local aF4For    := PARAMIXB[1]
Local lNfMedic	:= PARAMIXB[2]
Local lUsaFiscal:= PARAMIXB[3]
 
//A rotina so sera executada quando for pre-nota
If lAtesto  .And. !lUsaFiscal

	For nx	:= 1 to Len(aF4For)
		If aF4For[nx][1]
		
			If lProb
				Exit
			EndIf
		
			DbSelectArea("SC7")
			DbSetOrder(14)//FILIAL+PEDIDO
			DbGoTop() 
			
			cSeek := xFilEnt(xFilial("SC7")) + If( lNfMedic, aF4For[nx,6], aF4For[nx][3] ) 
			dbSeek(cSeek)
			
			Do While ( !Eof() .And. (SC7->C7_FILENT+SC7->C7_NUM == cSeek))  
			
			
			   	If (AllTrim(C7_NUMSC) == '') // Nao tem amarracao com solicitacao de compras
					MsgAlert("Existe pedido sem amarracao com solicitacao.","ATENCAO") 
					lProb := .T.
					Exit
				Else
					DbSelectArea("SC1")
					DbSetOrder(1)//C1_FILIAL+C1_NUM
					DbGoTop()   
					
					cSolic := xFilEnt(xFilial("SC1")) + SC7->C7_NUMSC
					dbSeek(cSolic) 
					             
					cxVer := C1_XSOL // Requisitante da Solicitacao

					If (cRequi == '') // Primeira vez que entrar, guarda o requisitante
	
				   		If (AllTrim(C1_XSOL) == '')
				   			MsgAlert("Existe solicitacao sem requisitante.","ATENCAO")  
					   		lProb := .T.
					   		Exit
				   		EndIf 
				   		
				   		cRequi := C1_XSOL
				   		
				 	ElseIf (cRequi <> cxVer)
				 	
				 		If (AllTrim(cxVer) == '')
				   			MsgAlert("Existe solicitacao sem requisitante.","ATENCAO")
				   		Else 
				 			MsgAlert("Existe solicitacao de requisitante diferente.","ATENCAO")
				 		EndIf
				 		  
						lProb := .T.
						Exit	 
				 	EndIf				
				EndIf 
			   
				DbSelectArea("SC7")    
				dbSkip()
			EndDo
			
		EndIf
	Next
	
	If lProb 
		aF4For := {}
		lRet := .F. 
	EndIf

EndIf

Return lRet       

//-------------------------------------------------------------------
/*/{Protheus.doc} COM120VL
Validacao do Acols da pre-nota

@author Bruna Paola
@since 09/06/2011
@version 1.0
/*/
//-------------------------------------------------------------------

User Function COM120VL(cRequi)

Local cSeek := ""
Local cSolic    := "" 
Local nx := 1 
Local lxProc := .F. 

	If (len(aCols) > 1)
	
		DbSelectArea("SC7")
		DbSetOrder(14)//FILIAL+PEDIDO+ITEM
		DbGoTop() 
		
		For nx:= 1 to (len(aCols)-1)
		                                                        
			If (!GDDELETED(nx) .And. lxProc == .F.) //Procura o primeiro item que nï¿½o esteja deletado 
				lxProc := .T.
				
				cSeek := xFilEnt(xFilial("SC7")) + (aCols[nx][aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_PEDIDO'})] + aCols[nx][aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_ITEMPC'})]) 
				dbSeek(cSeek)
		 
				
				//Verifica a amarracao com pedido
				If (Empty(aCols[nx][aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_PEDIDO'})]))
					MsgAlert("Existe Item sem amarracao com pedido.","ATENCAO")
					Return .T.
				EndIf
		
				DbSelectArea("SC1")
				DbSetOrder(1)//C1_FILIAL+C1_NUM
				DbGoTop()   
				
				cSolic := xFilEnt(xFilial("SC1")) + SC7->C7_NUMSC
				dbSeek(cSolic)
				   
				//Se requisitante da solicitacao do pedido for diferente do que ja existe no aCols, nao permite a inclusao
				If (cRequi <> C1_XSOL)
					MsgAlert("Existe solicitacao de requisitante diferente.","ATENCAO")
					Return .T.
				EndIf 
			EndIf
			 
		Next
	EndIf
	
Return .F.   

User Function CM120GR(nOpcA) 

Local nx := 1
Local cSeek := "" 
Local lAtesto   := GETMV("MV_XATESTO")  // parâmetro exclusivo CNI
Local cSolic    := "" 
                                        
If (lAtesto == .T.)

	For nx := 1 To (Len(aCols))
	
		If (!GDDELETED(nx)) //Procura o primeiro item que nï¿½o esteja deletado  
	
			DbSelectArea("SC7")
			DbSetOrder(14)//FILIAL+PEDIDO+ITEM
			DbGoTop() 
			
			cSeek := xFilEnt(xFilial("SC7")) + aCols[nx][aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_PEDIDO'})] + ; 
												aCols[nx][aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_ITEMPC'})] 
			dbSeek(cSeek) 
			
			//Verifica a amarracao com pedido - FSW(CNI) retirado a pedido do CSA
			If (Empty(aCols[nx][aScan(aHeader,{|x| AllTrim(x[2]) == 'D1_PEDIDO'})])  )
				MsgAlert("A pre-nota nao foi salva. Existe Item sem amarracao com pedido.","ATENCAO")
				nOpcA := 0
				Exit
			EndIf
			
			If (AllTrim(SC7->C7_NUMSC) == '') // Nao tem amarracao com solicitacao de compras 
				MsgAlert("A pre-nota nao foi salva. Existe Item sem amarracao com solicitacao.","ATENCAO") 	 
				nOpcA := 0
				Exit 
			EndIf
			
			DbSelectArea("SC1")
			DbSetOrder(1)//C1_FILIAL+C1_NUM
			DbGoTop()   
				
			cSolic := xFilEnt(xFilial("SC1")) + SC7->C7_NUMSC
			dbSeek(cSolic)
				   
			If U_COM120VL(C1_XSOL)
				nOpcA := 0
				Exit 
			EndIf
		EndIf	
	Next
EndIf

Return .T.