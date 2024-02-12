/*
 *   $Id: exemplo.prg 2256 2012-05-13 01:00:15Z leonardo $
 */

/* NOTE: Source of information:
         http://www.smssolutions.net/tutorials/gsm/receivesmsat/
         http://www.developershome.com/sms/readSmsByAtCommands.asp
         http://www.smssolutions.net/tutorials/gsm/sendsmsat/

Está levando em média 3 segundos para enviar cada mensagem, obtendo o retorno, sem retorno leva menos de 1 segundo

32000 segundos para 10000 mensagens
534   minutos  para 10000 mensagens
8:09  Horas    para 10000 mensagens

Web-service para consultar a operadora do CELULAR
http://www.telein.com.br/index.php/component/content/article/106
*/

#include "hwgui.ch"
#include "hbcompat.ch"

REQUEST HB_GT_GUI_DEFAULT

FUNCTION MAIN()

LOCAL oDIALOG, oBTN1, oBTN2
LOCAL oMSG, cMSG :=''
LOCAL oRETORNO, cRETORNO :=''
LOCAL oPORTA, nPORTA:=7, aPORTA:={}, nI
LOCAL oCEL, cCEL:='5191913474'
LOCAL oQUANT, nQUANT:=10

FOR nI := 1 TO 30
   AADD(aPORTA,'COM'+ALLTRIM(STR(nI)))
NEXT

INIT DIALOG oDIALOG TITLE "Teste para envio de SMS";
ICON HIcon():AddResource(1001) ;
AT 0,0 SIZE 265,390 ;
FONT HFont():Add( '',0,-13,400,,,) CLIPPER  NOEXIT ;
ON INIT{|| oDIALOG:nInitFocus:= oMSG:handle };
STYLE WS_POPUP+WS_CAPTION+DS_CENTER +WS_SYSMENU+WS_MINIMIZEBOX+WS_VISIBLE

  @ 15,23 SAY "Porta.:" SIZE 100,22
  @ 90,20 GET COMBOBOX oPORTA VAR nPORTA ITEMS aPORTA SIZE 155,24 ;
  TOOLTIP 'Informe a PORTA'

  @ 15,53 SAY "Celular:" SIZE 100,22
  @ 90,50 GET oCEL VAR cCEL SIZE 155,24 PICTURE '@R (99) 9999-9999';
  TOOLTIP 'Informe o numero do celular com DDD'

  @ 15,83 SAY "Quantidade:" SIZE 100,22
  @ 90,80 GET oQUANT VAR nQUANT SIZE 155,24 PICTURE '999';
  TOOLTIP 'Informe a quantidade de vez que deve enviar a mesma mensagem'

  @ 15,105 SAY "Mensagem:" SIZE 100,22
  @ 15,125 GET oMSG VAR cMSG  SIZE 230,74 ;
  FONT HFont():Add( '',0,-11,400,,,);
  STYLE WS_TABSTOP+WS_VSCROLL+ES_LEFT+ES_MULTILINE;
  TOOLTIP 'Informe a mensagem do SMS'

  @ 15,200 BUTTONEX oBTN1 CAPTION "&Enviar" SIZE 100, 28 ;
  TOOLTIP "Clique para conectar no dispositivo";
  ON CLICK {|| Envia_SMS(nPORTA,cCEL,cMSG,nQUANT,oRETORNO)};
  STYLE WS_TABSTOP

  @ 125,200 BUTTONEX oBTN2 CAPTION "&Fechar" SIZE 100, 28 ;
  TOOLTIP "Clique para fechar o aplicativo";
  ON CLICK {|| oDIALOG:CLOSE() };
  STYLE WS_TABSTOP

  @ 15,230 SAY "Retorno:" SIZE 100,22
  @ 15,250 GET oRETORNO VAR cRETORNO SIZE 230,104 ;
  FONT HFont():Add( '',0,-11,400,,,);
  STYLE WS_TABSTOP+WS_HSCROLL+WS_VSCROLL+ES_LEFT+ES_MULTILINE+ES_READONLY;
  TOOLTIP 'Informe o comando'

  ACTIVATE DIALOG oDIALOG

RETURN NIL

***********************************************************
STATIC FUNCTION ENVIA_SMS(nPORTA,cCEL,cMSG,nQUANT,oRETORNO)
***********************************************************
LOCAL nI, nINICIO:=0, nFIM:=0

IF nPORTA<=0
   MsgInfo('PORTA do servidor Invalido, Favor revisar')
   RETURN NIL
ENDIF

IF nQUANT <=0
   MsgInfo('Quantidade de vez Invalida, Favor revisar')
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

FOR nI := 1 TO nQUANT
   SMS_SEND( IIF(nPORTA>9,"\\.\COM","COM")+ALLTRIM(STR(nPORTA)) , cCEL , ALLTRIM(cMSG)+' - '+ALLTRIM(STR(nI)) , , oRETORNO )
NEXT

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

STATIC FUNCTION PORT_RECE( h, n, t )
LOCAL cString:=''
Local nLOOP  := 0
Local nESPERA:= 0
Local nBytesRecv:=0
LOCAL nINICIO:=0, nFIM:=0

IF ! HB_ISNUMERIC( n )
   n := 64
ENDIF

IF ! HB_ISNUMERIC( t )
   t := 5
ENDIF

cString := Space( n )
Millisec(100)
nINICIO:=TimeToSec(TIME())

DO WHILE .T.
   nLOOP=nLOOP+1
   nESPERA=nESPERA+1

   nBytesRecv:=hb_comRecv( h, @cString,, t )

   IF nBytesRecv >= n
      EXIT
   ENDIF

   IF !EMPTY(ALLTRIM(cString))
      EXIT
   ENDIF

   IF nESPERA = 1000
      Millisec(100)
      nESPERA = 0
   ENDIF

   IF nLOOP > 30000
      cString := "SEM_SINAL"
      EXIT
   ENDIF
   nFIM:=TimeToSec(TIME())

   IF nFim-nInicio>=20 //20 SEGUNDOS ELE CAI FORA
      EXIT
   ENDIF
ENDDO

RETURN cString

STATIC FUNCTION sms_Send( cPort, cPhoneNo, cText, cPIN, oRETORNO )
   LOCAL smsctx
   LOCAL nRetVal

   IF ! Empty( smsctx := smsctx_New( cPort ) )
      smsctx_PIN( smsctx, cPIN )
      nRetVal := smsctx_Send( smsctx, cPhoneNo, cText, oRETORNO )
      smsctx_Close( smsctx )
   ELSE
      oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() +'Erro: Não conectou a PORTA: '+ cPort )
      oRETORNO:REFRESH()
      nRetVal := -99
   ENDIF

   RETURN nRetVal

/* --------------------- */

#define _SMSCTX_xHnd          1
#define _SMSCTX_cPIN          2
#define _SMSCTX_cPrevName     3
#define _SMSCTX_MAX_          3

STATIC FUNCTION smsctx_New( xPort )
   LOCAL smsctx[ _SMSCTX_MAX_ ]

   IF HB_ISNUMERIC( xPort )
      smsctx[ _SMSCTX_xHnd ] := xPort
      smsctx[ _SMSCTX_cPrevName ] := NIL
   ELSEIF HB_ISSTRING( xPort )
      smsctx[ _SMSCTX_xHnd ] := 1
      smsctx[ _SMSCTX_cPrevName ] := hb_comGetDevice( smsctx[ _SMSCTX_xHnd ] )
      hb_comSetDevice( smsctx[ _SMSCTX_xHnd ], xPort )
   ELSE
      smsctx[ _SMSCTX_xHnd ] := NIL
   ENDIF

   IF smsctx[ _SMSCTX_xHnd ] != NIL
      IF hb_comOpen( smsctx[ _SMSCTX_xHnd ] )
         IF hb_comInit( smsctx[ _SMSCTX_xHnd ], 9600, "N", 8, 1 )
            RETURN smsctx
         ELSE
            hb_comClose( smsctx[ _SMSCTX_xHnd ] )
         ENDIF
      ENDIF
   ENDIF

   RETURN NIL

STATIC FUNCTION smsctx_Close( smsctx )

   IF ! HB_ISARRAY( smsctx ) .OR. Len( smsctx ) != _SMSCTX_MAX_
      RETURN .F.
   ENDIF

   IF ! hb_comClose( smsctx[ _SMSCTX_xHnd ] )
      RETURN .F.
   ENDIF

   /* Restore com port name */
   IF smsctx[ _SMSCTX_cPrevName ] != NIL
      hb_comSetDevice( smsctx[ _SMSCTX_xHnd ], smsctx[ _SMSCTX_cPrevName ] )
   ENDIF

   RETURN .T.

STATIC FUNCTION smsctx_Send( smsctx, cPhoneNo, cText, oRETORNO )
   LOCAL tmp

   IF ! HB_ISARRAY( smsctx ) .OR. Len( smsctx ) != _SMSCTX_MAX_
      RETURN -1
   ENDIF

   IF ! Empty( smsctx[ _SMSCTX_cPIN ] ) // SE TIVER UM PIN PREENCHIDO
      hb_comSend( smsctx[ _SMSCTX_xHnd ], 'AT+CPIN="' + smsctx[ _SMSCTX_cPIN ] + '"' + Chr( 13 ) )
      tmp:=StripCRLF( port_rece( smsctx[ _SMSCTX_xHnd ] ) )
      IF !( right(tmp,2) == "OK" )
         oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() +"Erro: PIN Invalido: "+valtoprg(tmp))
         oRETORNO:REFRESH()
         RETURN -5
      ENDIF
   ENDIF

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

FUNCTION smsctx_PIN( smsctx, cPIN )
   LOCAL cOldValue

   IF ! HB_ISARRAY( smsctx ) .OR. Len( smsctx ) != _SMSCTX_MAX_
      RETURN NIL
   ENDIF

   cOldValue := smsctx[ _SMSCTX_cPIN ]
   IF cPIN == NIL .OR. ( HB_ISSTRING( cPIN ) .AND. Len( cPIN ) == 4 )
      smsctx[ _SMSCTX_cPIN ] := cPIN
   ENDIF

   RETURN cOldValue

STATIC FUNCTION StripCRLF( cString )
   RETURN StrTran( alltrim(cString), Chr( 13 ) + Chr( 10 ) )

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

