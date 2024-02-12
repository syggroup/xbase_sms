/*
 *   $Id: exemplo.prg 2256 2012-05-13 01:00:15Z leonardo $
 */

/* NOTE: Source of information:
         http://www.smssolutions.net/tutorials/gsm/receivesmsat/
         http://www.developershome.com/sms/readSmsByAtCommands.asp
         http://www.smssolutions.net/tutorials/gsm/sendsmsat/

Está levando em média 17 segundos para enviar cada mensagem

*/

#include "hwgui.ch"

#define x_BLUE       16711680
#define x_DARKBLUE   10027008
#define x_WHITE      16777215
#define x_CYAN       16776960
#define x_BLACK             0
#define x_RED             255
#define x_GREEN         32768
#define x_GRAY        8421504
#define x_YELLOW        65535
#define x_GRAY2       8421440
#define CORPADRAO  COLOR_3DLIGHT+3

FUNCTION MAIN()

LOCAL oDIALOG, oBTN1, oBTN2, oServer, oQUERY
LOCAL oMSG, cMSG :=''
LOCAL oRETORNO, cRETORNO :=''
LOCAL oPORTA, nPORTA:=9, aPORTA:={}, nI
LOCAL oCEL, cCEL:='5191913474'

FOR nI := 1 TO 30
   AADD(aPORTA,'COM'+ALLTRIM(STR(nI)))
NEXT

oServer := TPQServer():New( 'localhost', 'cofarja', 'sygecom', '253565', NIL, NIL )
IF oServer:NetErr()
   MY_ShowMsg('Erro ao conectar: ' + valtoprg(oServer:ErrorMsg()))
   RETURN
ELSE
   MY_ShowMsg('Conectou com Sucesso no banco de dados',5)
ENDIF

INIT DIALOG oDIALOG TITLE "Teste para envio de SMS";
ICON HIcon():AddResource(1001) ;
AT 0,0 SIZE 265,390 ;
FONT HFont():Add( '',0,-13,400,,,) CLIPPER  NOEXIT ;
ON INIT{|| oDIALOG:nInitFocus:= oCEL:handle };
STYLE WS_POPUP+WS_CAPTION+DS_CENTER +WS_SYSMENU+WS_MINIMIZEBOX+WS_VISIBLE

  @ 15,23 SAY "Porta.:" SIZE 100,22
  @ 90,20 GET COMBOBOX oPORTA VAR nPORTA ITEMS aPORTA SIZE 100,24 ;
  TOOLTIP 'Informe a PORTA'

  @ 15,83 SAY "Celular:" SIZE 100,22
  @ 90,80 GET oCEL VAR cCEL SIZE 155,24 PICTURE '@R (99) 9999-9999';
  TOOLTIP 'Informe o numero do celular com DDD'

  @ 15,105 SAY "Mensagem:" SIZE 100,22
  @ 15,125 GET oMSG VAR cMSG  SIZE 230,74 ;
  FONT HFont():Add( '',0,-11,400,,,);
  STYLE WS_TABSTOP+WS_VSCROLL+ES_LEFT+ES_MULTILINE;
  TOOLTIP 'Informe a mensagem do SMS'

  @ 15,200 BUTTONEX oBTN1 CAPTION "&Enviar" SIZE 100, 28 ;
  TOOLTIP "Clique para conectar no dispositivo";
  ON CLICK {|| Envia_SMS(nPORTA,cCEL,cMSG,oRETORNO)};
  STYLE WS_TABSTOP

  @ 125,200 BUTTONEX oBTN2 CAPTION "&Fechar" SIZE 100, 28 ;
  TOOLTIP "Clique para fechar o aplicativo";
  ON CLICK {|| oQUERY:=oServer:Query('select * from cag_ent'),   MY_BROWSE(oQUERY[15])    };
  STYLE WS_TABSTOP

  @ 15,230 SAY "Retorno:" SIZE 100,22
  @ 15,250 GET oRETORNO VAR cRETORNO SIZE 230,104 ;
  FONT HFont():Add( '',0,-11,400,,,);
  STYLE WS_TABSTOP+WS_HSCROLL+WS_VSCROLL+ES_LEFT+ES_MULTILINE+ES_READONLY;
  TOOLTIP 'Informe o comando'

  ACTIVATE DIALOG oDIALOG

  oServer:Destroy()
  MY_ShowMsg('Desconectou do Bando de dados',5)

RETURN NIL

****************************************************
STATIC FUNCTION ENVIA_SMS(nPORTA,cCEL,cMSG,oRETORNO)
****************************************************
LOCAL nINICIO:=0, nFIM:=0
LOCAL nIDPORT:=0
LOCAL cRET:=''

IF nPORTA<=0
   MsgInfo('PORTA do servidor Invalido, Favor revisar')
   RETURN NIL
ENDIF

IF EMPTY(cCEL)
   MsgInfo('Favor informar o numero do celular')
   RETURN NIL
ELSE
   IF LEN(cCEL) < 10
      MsgInfo('Numero do celular invalido, favor revisar')
   	  RETURN NIL
   ENDIF
   cCEL:=ALLTRIM(cCEL)
ENDIF

IF EMPTY(cMSG)
   MsgInfo('Favor informar uma mensagem')
   RETURN NIL
ELSE
   IF LEN(cMSG) > 150
      MsgInfo('A Mensagem não pode passar de 150 caracteres, favor revisar')
	  RETURN NIL
   ENDIF
   cMSG:=ALLTRIM(cMSG)
ENDIF

Private oDlgHabla:=nil
MsgRun("Aguarde, Enviando SMS...")

nINICIO:=TimeToSec(TIME())

oRETORNO:SETTEXT("Iniciando...")
oRETORNO:REFRESH()

nIDPORT:=ABRIR_PORTA_COM(nPORTA,9600,8,1,'N') // ABRE A PORTA
IF nIDPORT > 0
   cRET:=ENVIA_COMANDO(nIDPORT,"AT+CMGF=1" + Chr( 13 ))
   IF RIGHT(cRET,2) = "OK" // SE O MODEM É COMPATIVEL COM MODO TEXTO
      cRET:= ENVIA_COMANDO(nIDPORT,'AT+CMGS="' + cCEL + '"' + Chr( 13 ) )
      IF Right(cRET,1) = ">" // SE CONSEGUE ENVIAR PARA O NUMERO A MENSAGEM
         cRET:=ENVIA_COMANDO(nIDPORT,StrTran( cMSG, Chr( 13 ) ) + Chr( 26 )) // ENVIA MENSAGEM DE TEXTO

         // O RETORNO GERALMENTE É: CMGS: + O ID DE IDENTIFICAÇÃO DA MENSAGEM
         //CMS ERROR: 500  // DEU ERRO COM NUMERO 1111-1111
         //+CME ERROR: unknown // ENVIOU COM SUCESSO
         //REG: 1, C44B    // ENVIO COM SUCESSO
         //+CMGS:          // ENVIO COM SUCESSO

         //IF Left( tmp, Len( "+CMGS: " ) ) == "+CMGS: "
         IF "+CMGS:"$cRET
            oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() +"Enviado com Sucesso")
            oRETORNO:REFRESH()
         ELSE
            oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() +"Erro: "+valtoprg(cRET) )
            oRETORNO:REFRESH()
         ENDIF
      ELSE
         oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() +"Erro: numero de Celular imcompativel: " + valtoprg(cRET))
         oRETORNO:REFRESH()
      ENDIF
   ELSE
      oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() +'Erro: Modem Incompativel com modo Texto :' + valtoprg(cRET) )
      oRETORNO:REFRESH()
   ENDIF

   CloseComm( nIDPORT ) // FECHA PORTA
ELSE
   oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() +'Erro: Não conectou a PORTA: '+ STR(nPORTA) )
   oRETORNO:REFRESH()
ENDIF

FIM_RUN()

nFIM:=TimeToSec(TIME())

oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() + "Tempo Total: "+sectotime(nFim-nInicio))
oRETORNO:REFRESH()

IF 'ERRO'$UPPER(oRETORNO:GETTEXT())
   MsgInfo('Erro ao enviar o SMS')
ELSE
   MsgInfo('SMS enviado com Sucesso')
ENDIF

RETURN NIL

**********************************************
STATIC FUNCTION RECEBE_COMANDO(nIDPORT,nSPACE)
**********************************************
LOCAL cRET   := SPACE(nSPACE), nBYTES
LOCAL nLOOP  := 0
LOCAL nESPERA:= 0
LOCAL nINICIO:= 0
LOCAL nFIM   := 0

Millisec(100)
nINICIO:=TimeToSec(TIME())

DO WHILE .T.
   nLOOP=nLOOP+1
   nESPERA=nESPERA+1
   nBYTES := ReadComm( nIDPORT, @cRET)

   IF nBYTES >= nSPACE
      EXIT
   ENDIF

   IF !EMPTY(ALLTRIM(cRET))
      EXIT
   ENDIF

   IF nESPERA = 1000
      Millisec(100)
      nESPERA = 0
   ENDIF

   IF nLOOP > 30000
      cRET := "SEM_SINAL"
      EXIT
   ENDIF
   nFIM:=TimeToSec(TIME())

   IF nFim-nInicio>=20 // QUANDO CHEGAR EM 20 SEGUNDOS ELE CAI FORA, POR QUE NÃO PODE DEMORAR MAIS QUE ISSO
      EXIT
   ENDIF
ENDDO
cRET:=ALLTRIM(cRET)
cRET:=STRTRAN( alltrim(cRET), Chr( 13 ) + Chr( 10 ) )
RETURN(cRET)

***********************************************
STATIC FUNCTION ENVIA_COMANDO(nIDPORT,cCOMANDO)
***********************************************
LOCAL cRET:='', nBYTES:=0

if ( nBYTES := WriteComm( nIDPORT, cCOMANDO ) ) < 0
   MsgStop( "Erro ao Enviar o parametro: "+cCOMANDO)
endif
Millisec(100)
cRET:=RECEBE_COMANDO(nIDPORT,64)
RETURN(cRET)

***********************************************************************
FUNCTION ABRIR_PORTA_COM(nPORTA,nBAUD,nWORDBIT,nSTOPBIT,cTIPO_PARIDADE)
***********************************************************************
LOCAL nIDPORT,cDCB,cBUILD,nBytes

if nPORTA > 9
   nIDPORT := OPENCOMM('\\.\COM'+STR(nPORTA,2),1024,256)
else
   nIDPORT := OPENCOMM("COM"+STR(nPORTA,1),1024,256)
endif

IF nIDPORT <= 0
   MsgStop( "Erro ao abrir a Porta: COM" + Str( nPORTA )+", Favor revisar se a porta está em uso por outro programa"  )
   CloseComm( nIDPORT )
   RETURN 0
else
   if FlushComm( nIDPORT, 0 ) != 0
      MsgStop( "Erro ao abrir a Porta: COM" + Str( nPORTA )+", Favor revisar se a porta está em uso por outro programa"  )
      CloseComm( nIDPORT )
      RETURN 0
   endif
ENDIF

IF nPORTA > 9
   cBUILD="COM"+STR(nPORTA,2)+":"+alltrim(str(nBAUD))+","+cTIPO_PARIDADE+","+alltrim(str(nWORDBIT))+","+alltrim(str(nSTOPBIT))
ELSE
   cBUILD="COM"+STR(nPORTA,1)+":"+alltrim(str(nBAUD))+","+cTIPO_PARIDADE+","+alltrim(str(nWORDBIT))+","+alltrim(str(nSTOPBIT))
ENDIF
IF ! BuildCommDcb(cBUILD, @cDCB)
   MsgStop( "Erro ao abrir a Porta: COM" + Str( nPORTA )+", Favor revisar se a porta está em uso por outro programa"  )
   CloseComm( nIDPORT )
   RETURN 0
ELSE
   IF ! SetCommState( nIDPORT, cDCB )
      MsgStop( "Erro ao abrir a Porta: COM" + Str( nPORTA )+", Favor revisar se a porta está em uso por outro programa"  )
      CloseComm( nIDPORT )
      RETURN 0
   ENDIF
ENDIF

if FlushComm( nIDPORT, 0 ) != 0
   ShowMsg( "Erro ao Resetar a Porta: COM" + Str( nPORTA )+", Favor revisar se a Porta não está sendo usada por outro programa" )
   CloseComm( nIDPORT )
   RETURN 0
endif

RETURN nIDPORT

/*
STATIC FUNCTION smsctx_Send( smsctx, cPhoneNo, cText, oRETORNO )
   LOCAL tmp

   hb_comSend( smsctx[ _SMSCTX_xHnd ], "AT+CMGF=1" + Chr( 13 ) )
   tmp := StripCRLF( port_rece( smsctx[ _SMSCTX_xHnd ] ) )

   IF right(tmp,2) = "OK" // SE O MODEM É COMPATIVEL COM MODO TEXTO
      hb_comSend( smsctx[ _SMSCTX_xHnd ], 'AT+CMGS="' + cPhoneNo + '"' + Chr( 13 ) )
      tmp:=StripCRLF( port_rece( smsctx[ _SMSCTX_xHnd ] ) )

      IF Right(tmp,1) = ">" // SE CONSEGUE ENVIAR PARA O NUMERO A MENSAGEM
         hb_comSend( smsctx[ _SMSCTX_xHnd ], StrTran( cText, Chr( 13 ) ) + Chr( 26 ) )
         tmp := port_rece( smsctx[ _SMSCTX_xHnd ] )

         // O RETORNO GERALMENTE É: CMGS: + O ID DE IDENTIFICAÇÃO DA MENSAGEM
         //CMS ERROR: 500  // DEU ERRO COM NUMERO 1111-1111
         //REG: 1, C44B    // ENVIO COM SUCESSO
         //+CMGS:          // ENVIO COM SUCESSO

         //IF Left( tmp, Len( "+CMGS: " ) ) == "+CMGS: "
         IF "+CMGS:"$tmp
            oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() +"Enviado com Sucesso")
            oRETORNO:REFRESH()
            RETURN 0
         ELSE
            oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() +"Erro:"+valtoprg(tmp) )
            oRETORNO:REFRESH()
            RETURN -10
         ENDIF
      ELSE
         oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() +"Erro com Celular:"+valtoprg(tmp))
         oRETORNO:REFRESH()
         RETURN -11
      ENDIF
   ELSE
      oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() +"Erro: Modem Incompativel ou Porta errada")
      oRETORNO:REFRESH()
      RETURN -12
   ENDIF
RETURN -2

STATIC FUNCTION StripCRLF( cString )
   RETURN StrTran( alltrim(cString), Chr( 13 ) + Chr( 10 ) )
*/

*************************************
STATIC FUNCTION MsgRun( cMsg, bEval )
**************************************
MsgRun2(cMsg)
HW_Atualiza_Dialogo(cMsg)
if ValType(bEval) = 'B'
   EVAL( bEval )
   Fim_Run()
endif
Return

*****************************
STATIC FUNCTION MSGRUN2(cMsg)
*****************************
Local oTimHabla

if cMsg=Nil
   cMsg:="Aguarde em processamento...."
endif

INIT DIALOG oDlgHabla TITLE "Processando..." NOEXIT NOEXITESC ;//NOCLOSABLE;
AT 0,0 SIZE 485,60 ;
STYLE WS_POPUP+WS_SYSMENU+WS_SIZEBOX+DS_CENTER;
COLOR Rgb(255, 255, 255)

@ 45,26 SAY oTimHabla CAPTION cMsg SIZE 465,20;
FONT HFont():Add( '',0,-11,400,,,);
BACKCOLOR Rgb(255, 255, 255)

ACTIVATE DIALOG oDlgHabla NOMODAL

Return Nil

***********************
STATIC FUNCTION FIM_RUN
***********************
IF oDlgHabla # NIL
   oDlgHabla:CLOSE()
ENDIF
Return Nil

**********************************************
STATIC FUNCTION HW_ATUALIZA_DIALOGO(cMENSAGEM)
**********************************************
IF cMENSAGEM=nIL
   cMENSAGEM:="Aguarde em processamento...."
endif

TRY
   oDlgHabla:ACONTROLS[1]:SETTEXT(cMENSAGEM)
catch e
//   HWG_DOEVENTS()
END
RETURN NIL

FUNCTION HB_ZIPFILE
RETURN NIL

FUNCTION GETFILEVERSIONINFO
RETURN NIL

FUNCTION LISTA_TABELAS
RETURN NIL


*****************************************************
FUNCTION MY_BROWSE(aARRAY_BRW,cTITULO,lEDIT,aCOLUNAS)
*****************************************************
/*
aARRAY_BRW = VETOR COM O CONTEUDO QUE DESEJA VISUALIZAR OU ALTERAR
cTITULO    = TITULO DA JANELA
lEDIT      = SE .T. PODE ALTERAR O CAMPO, SE .F. APENAS VISUALIZA
aCOLUNAS   = VETOR CONTENDO OS NOMES DAS COLUNAS, UTIL PARA QUANDO É BROWSE DE VETOR
NOTA: QUANDO ABRI UM DBF, SELECIONA A AREA DO DBF E CHAMA A FUNÇÃO MY_BROWSE() ELE JÁ SE ENCARREGA DE MOSTRAR TUDO NA TELA, COMO O ANTIGO
BROWSE() DO CLIPPER
*/
Local nI, nI3, oFrm_Browse, oBRW_BROWSE, nLen:=0
Local aArq:={}, aArq2:={}
Local cFILE    := ALIAS()
Local aCAMPOS  := {}
Local oBUS,cBUS:=''
Local oORDEM, cORDEM:='', aORDEM:={}

IF lEDIT=NIL
   lEDIT:=.F.
ENDIF

IF aARRAY_BRW=Nil
   IF EMPTY(cFILE)
      MsgStop("Não foi selecionado nenhuma tabela, Favor revisar")
      Return
   ENDIF

   SELE &cFILE // seleciona a area
   aStruct := DbStruct()  // pega a estrutura

   FOR nI := 1 TO Len(aStruct)
       IF aStruct[nI,2]="D"
          aStruct[nI,3]:=aStruct[nI,3]+2
       ENDIF
       AADD(aCAMPOS ,{aStruct[nI,1],aStruct[nI,2],aStruct[nI,3],aStruct[nI,4]} )
       AADD(aORDEM,aStruct[nI,1])
   NEXT
ELSE
   cFILE:="TABELA TEMPORARIA (VETOR)"
   IF aARRAY_BRW=NIl
      Erroreg()
      Return
   ELSE
      IF LEN(aARRAY_BRW)=0
         Erroreg()
         Return
      ENDIF
   ENDIF
   IF aCOLUNAS#Nil
      IF LEN(aCOLUNAS) > 0
         FOR nI := 1 TO Len(aCOLUNAS)
            AADD(aORDEM,aCOLUNAS[nI])
         NEXT
      ELSE
         FOR nI := 1 TO Len(aARRAY_BRW)
            AADD(aORDEM,"Coluna: " + alltrim(str(nI)))
         NEXT
      ENDIF
   ELSE
      FOR nI := 1 TO Len(aARRAY_BRW)
         AADD(aORDEM,"Coluna: " + alltrim(str(nI)))
      NEXT
   ENDIF
ENDIF
cORDEM:=aORDEM[1]

IF cTITULO=Nil
   cTITULO:="Registros da Tabela: " + cFILE
ENDIF

INIT DIALOG oFrm_Browse TITLE cTITULO CLIPPER;
FONT HFont():Add( '',0,-14,400,,,);
AT 0,0;
SIZE GETDESKTOPWIDTH(),GETDESKTOPHEIGHT()-50 ;
ICON HIcon():AddResource(1001) ;
ON INIT  {|| (oFrm_Browse:nInitFocus := oBRW_BROWSE:handle),.T.};
STYLE DS_CENTER + WS_VISIBLE + WS_CAPTION + WS_SYSMENU

@ oFrm_Browse:nWidth-110,oFrm_Browse:nHeight-50  BUTTONEX "&Fechar" SIZE 100, 38 ;
TOOLTIP "Sair do Modulo e Voltar aos Menus";
ON CLICK {|| oFrm_Browse:Close() };
BITMAP (HBitmap():AddResource(1003)):handle  ;
STYLE WS_TABSTOP

IF aARRAY_BRW=Nil
   @ 10,40 BROWSE oBRW_BROWSE DATABASE OF oFrm_Browse;
   SIZE oFrm_Browse:nWidth-20,oFrm_Browse:nHeight-130 ;
   STYLE  WS_VSCROLL + WS_HSCROLL;
   FONT HFont():Add( '',0,-12,400,,,);
   MULTISELECT

   oBRW_BROWSE:alias := ALIAS()
ELSE
   @ 05,oFrm_Browse:nHeight-80 SAY "Pesquisa:"  SIZE 50,22 COLOR x_BLUE
   @ 75,oFrm_Browse:nHeight-84 GET COMBOBOX oORDEM VAR cORDEM ITEMS aORDEM SIZE 150,22  TEXT ;
   DISPLAYCOUNT 27;
   ON CHANGE{|| oBUS:SETFOCUS(),.T. };
   FONT HFont():Add( '',0,-11,400,,,);
   TOOLTIP 'Escolha a Ordem da Pesquisa'

   @ 10,40 BROWSE oBRW_BROWSE Array OF oFrm_Browse;
   SIZE oFrm_Browse:nWidth-20,oFrm_Browse:nHeight-130 ;
   STYLE  WS_VSCROLL + WS_HSCROLL;
   FONT HFont():Add( '',0,-11,400,,,);
   MULTISELECT

   oBRW_BROWSE:aArray := aARRAY_BRW
   CreateArList( oBRW_BROWSE, aARRAY_BRW )
ENDIF

oBRW_BROWSE:bKeyDown := {|o,key,c,d| BrowseKey_alt(o, key,c,d, cTITULO ) }

oBRW_BROWSE:Freeze:=1
oBRW_BROWSE:lESC:=.T.

@ 5,10 SAY "F1 - Sobre  / F2 - Busca  / F4 - Muda Ordem  / F5 - Gera Excel  / F9 - Calculadora" size oFrm_Browse:nWidth,20;
STYLE SS_CENTER COLOR x_BLUE

IF aARRAY_BRW=Nil
   AEVAL(aCAMPOS,;
   {|cVAL,nIND| oBRW_BROWSE:addcolumn(HColumn():New( aCAMPOS[nIND,1], FieldBlock(aCAMPOS[nIND,1]) ,,aCAMPOS[nIND,3],aCAMPOS[nIND,4],lEDIT,0,0,,,,,,)) })
ENDIF

FOR nI := 1 TO Len(oBRW_BROWSE:aColumns)
    IF aCOLUNAS#Nil
       IF LEN(aCOLUNAS) >= nI
          IF VALTYPE(aCOLUNAS[nI])='U'
             oBRW_BROWSE:aColumns[nI]:heading   := "Coluna: " + alltrim(str(nI))
          ELSE
             oBRW_BROWSE:aColumns[nI]:heading   := aCOLUNAS[nI]
          ENDIF
       ENDIF
    ELSE
       IF aARRAY_BRW#Nil
          oBRW_BROWSE:aColumns[nI]:heading   := "Coluna: " + alltrim(str(nI))
       ENDIF
    ENDIF

    oBRW_BROWSE:aColumns[nI]:lEditable := lEDIT
    oBRW_BROWSE:aColumns[nI]:nJusHead  := DT_CENTER    //CENTRALIZA NO NOME DO CAMPO
    oBRW_BROWSE:aColumns[nI]:nJusLin   := DT_LEFT     //COLOCA PARA DIREITA A LINHA
*    IF aARRAY_BRW#Nil
*       oBRW_BROWSE:aColumns[nI]:bHeadClick := {|| Atualiza_brw_nf2(aARRAY_BRW,nCOLUNA,oBRW_BROWSE) }
*    ENDIF

*    FOR nI3 := 1 TO LEN(aARRAY_BRW[nI])
*        IF !EMPTY(aARRAY_BRW[nI,nI3])
*           IF VALTYPE( aARRAY_BRW[nI,nI3] )= "C"
*              oBRW_BROWSE:aColumns[nI]:length := Max( nLen, Len( aARRAY_BRW[nI,nI3] ) )+2
*           ENDIF
*        ENDIF
*    NEXT

    IF aARRAY_BRW=Nil
       oBRW_BROWSE:aColumns[nI]:bColorBlock := {|| IF(Deleted() ,{x_RED ,  x_WHITE, x_GREEN, x_CYAN} ,;
                                                   IF(!Deleted(),{x_BLUE,  x_WHITE, x_GREEN, x_CYAN} , {x_BLACK, x_WHITE , x_GREEN, x_CYAN } ) ) }
    ENDIF
NEXT

ACTIVATE DIALOG oFrm_Browse //Show SW_SHOWMAXIMIZED

Return( IIF( LEN(oBRW_BROWSE:aSelected)=0,{oBRW_BROWSE:nCURRENT}, oBRW_BROWSE:aSelected) )

***************************************************************
STATIC FUNCTION BROWSEKEY_ALT( oBrowse, key, p1, p2, cTITULO )
***************************************************************
DO CASE
   CASE KEY = VK_RETURN
        EndDialog()
   CASE KEY= VK_ESCAPE
        EndDialog()
   CASE KEY = VK_F5
        Gera_Excel(oBrowse)
   CASE KEY = VK_F9
        ShellExecute("calc")
   otherwise
ENDCASE
Return .T.
