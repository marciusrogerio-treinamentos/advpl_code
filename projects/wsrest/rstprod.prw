#Include 'Protheus.ch'
#Include 'FWMVCDEF.ch'
#Include 'RestFul.CH'

User Function EREST_01()
Return

WSRESTFUL PRODUTOS DESCRIPTION "Serviço REST para manipulação de Produtos"

WSDATA CODPRODUTO As String

    WSMETHOD GET DESCRIPTION "Retorna o produto informado na URL" WSSYNTAX "/PRODUTOS || /PRODUTOS/{}"

END WSRESTFUL

WSMETHOD GET WSRECEIVE CODPRODUTO WSSERVICE PRODUTOS
    Local cCodProd := Self:CODPRODUTO
    Local aArea    := GetArea()
    Local oObjProd := Nil
    Local cStatus  := ""
    Local cJson    := ""

    ::SetContentType("application/json")

    DbSelectArea("SB1")
    SB1->( DbSetOrder(1) )
    If SB1->( DbSeek( xFilial("SB1") + cCodProd ) )
        cStatus  := Iif( SB1->B1_MSBLQL == "1", "Sim", "Nao" )
        oObjProd :="'descricao':'"+alltrim(SB1->B1_DESC)+"',"
        oObjProd +="'bloqueado':'"+cStatus+"',"
        oObjProd +="'codigo':'"+alltrim(SB1->B1_COD)+"'"
    EndIf

    cJson := FWJsonSerialize(oObjProd)

    ::SetResponse(cJson)

    RestArea(aArea)
Return(.T.)
