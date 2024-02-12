/*
 *   $Id: exemplo.prg 2502 2012-06-25 12:32:48Z leonardo $
 */

#include "hwgui.ch"

/*
Baseado na documentação do nowsms
http://www.nowsms.com/doc/submitting-sms-messages/sending-sms-text-messages
http://www.nowsms.com/doc/submitting-sms-messages/sending-sms-text-messages
*/

FUNCTION MAIN(...)

LOCAL oDIALOG, oBTN1, oBTN2
LOCAL oMSG, cMSG :=''
LOCAL oRETORNO, cRETORNO :=''
LOCAL oIP, cIP:='sygecomsms.no-ip.info', oPORTA, nPORTA:=8800
LOCAL oCEL, cCEL:='5191913474'
LOCAL nI, aPARA:=HB_AParams()
LOCAL oQUANT, nQUANT:=10

IF LEN(aPARA) >0
   cCEL:=ALLTRIM(aPARA[1])

   FOR nI=2 to LEN(aPARA)
      cMSG+=ALLTRIM(ALLTRIM(aPARA[nI]))+' '
   NEXT
ENDIF

INIT DIALOG oDIALOG TITLE "Teste para envio de SMS";
ICON HIcon():AddResource(1001) ;
AT 0,0 SIZE 265,420 ;
FONT HFont():Add( '',0,-13,400,,,) CLIPPER  NOEXIT ;
ON INIT{|| oDIALOG:nInitFocus:= oMSG:handle };
STYLE WS_POPUP+WS_CAPTION+DS_CENTER +WS_SYSMENU+WS_MINIMIZEBOX+WS_VISIBLE

//STYLE DS_CENTER +WS_VISIBLE+WS_MINIMIZEBOX

  @ 15,23 SAY "IP / URL.:" SIZE 100,22
  @ 90,20 GET oIP VAR cIP  SIZE 155,24 ;
  STYLE ES_AUTOHSCROLL;
  TOOLTIP 'Informe o IP ou URL do servidor onde está instalado o Now SMS Gateway'

  @ 15,53 SAY "Porta:" SIZE 100,22
  @ 90,50 GET oPORTA VAR nPORTA  SIZE 155,24 ;
  TOOLTIP 'Informe o numero da porta que está sendo usado no Now SMS Gateway'

  @ 15,83 SAY "Celular:" SIZE 100,22
  @ 90,80 GET oCEL VAR cCEL SIZE 155,24 PICTURE '@R (99) 9999-9999';
  TOOLTIP 'Informe o numero do celular com DDD'

  @ 15,113 SAY "Quantidade:" SIZE 100,22
  @ 90,110 GET oQUANT VAR nQUANT SIZE 155,24 PICTURE '999';
  TOOLTIP 'Informe a quantidade de vez que deve enviar a mesma mensagem'

  @ 15,135 SAY "Mensagem:" SIZE 100,22
  @ 15,155 GET oMSG VAR cMSG  SIZE 230,74 ;
  FONT HFont():Add( '',0,-11,400,,,);
  STYLE WS_TABSTOP+WS_VSCROLL+ES_LEFT+ES_MULTILINE;
  TOOLTIP 'Informe a mensagem do SMS'

  @ 15,230 BUTTONEX oBTN1 CAPTION "&Enviar" SIZE 100, 28 ;
  TOOLTIP "Clique para conectar no dispositivo";
  ON CLICK {|| Envia_SMS(cIP,nPORTA,cCEL,cMSG,nQUANT,oRETORNO)};
  STYLE WS_TABSTOP

  @ 125,230 BUTTONEX oBTN2 CAPTION "&Fechar" SIZE 100, 28 ;
  TOOLTIP "Clique para fechar o aplicativo";
  ON CLICK {|| oDIALOG:CLOSE() };
  STYLE WS_TABSTOP

  @ 15,260 SAY "Retorno:" SIZE 100,22
  @ 15,280 GET oRETORNO VAR cRETORNO SIZE 230,104 ;
  FONT HFont():Add( '',0,-11,400,,,);
  STYLE WS_TABSTOP+WS_HSCROLL+WS_VSCROLL+ES_LEFT+ES_MULTILINE+ES_READONLY;
  TOOLTIP 'Informe o comando'

  ACTIVATE DIALOG oDIALOG

RETURN NIL

***************************************************************
STATIC FUNCTION ENVIA_SMS(cIP,nPORTA,cCEL,cMSG,nQUANT,oRETORNO)
***************************************************************
LOCAL cURL:='http://', oHttp, cHtml:='', nI

IF EMPTY(cIP)
   MsgInfo('IP do servidor Invalido, Favor revisar')
   RETURN NIL
ENDIF

IF nPORTA=0
   MsgInfo('Porta do servidor Invalida, Favor revisar')
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
   cCEL:='%2B55'+ALLTRIM(cCEL)
ENDIF

IF EMPTY(cMSG)
   MsgInfo('Favor informar uma mensagem')
   RETURN NIL
ELSE
   IF LEN(cMSG) > 160
      MsgInfo('A Mensagem não pode passar de 160 caracteres, favor revisar')
	  RETURN NIL
   ENDIF
   cMSG:=ALLTRIM(cMSG)
   cMSG:=STRTRAN(cMSG,' ','+')
ENDIF

Private oDlgHabla:=nil
MsgRun("Aguarde, Enviando SMS...")

//http://127.0.0.1:8800/?PhoneNumber=%2B555191913474&Text=leo+def+ghi

cURL:='http://'+ALLTRIM(cIP)+':'+ALLTRIM(STR(nPORTA))+'/?PhoneNumber='+cCEL+'&Text='+cMSG //+'&ReplyRequested=Yes&SMSCRoute=SAGI'
oRETORNO:SETTEXT("Enviou comando: " + cURL )
oRETORNO:REFRESH()

FOR nI := 1 TO nQUANT
   cURL:='http://'+ALLTRIM(cIP)+':'+ALLTRIM(STR(nPORTA))+'/?PhoneNumber='+cCEL+'&Text='+cMSG+'-'+ALLTRIM(STR(nI)) //+'&ReplyRequested=Yes&SMSCRoute=SAGI'

   oHttp:=TipClientHttp():new( cURL )
   oHttp:open()
   cHtml := oHttp:readAll()
   oHttp:close()

   IF !EMPTY(cHtml)
      oRETORNO:SETTEXT(oRETORNO:GETTEXT()+ HB_OsNewLine() +"Retorno: " + cHtml )
      oRETORNO:REFRESH()
   ENDIF
NEXT

FIM_RUN()

IF !EMPTY(cHtml)
   MsgInfo('SMS enviado com Sucesso')
ELSE
   MsgInfo('Erro ao enviar o SMS, talvez o servidor esteja fora do AR')
ENDIF

RETURN NIL

******************************
FUNCTION MsgRun( cMsg, bEval )
******************************
MsgRun2(cMsg)
HW_Atualiza_Dialogo(cMsg)
if ValType(bEval) = 'B'
   EVAL( bEval )
   Fim_Run()
endif
Return

*********************
FUNCTION MsgRun2(cMsg)
*********************
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

****************
FUNCTION FIM_RUN
****************
IF oDlgHabla # NIL
   oDlgHabla:CLOSE()
ENDIF
Return Nil

***************************************
FUNCTION HW_ATUALIZA_DIALOGO(cMENSAGEM)
***************************************
IF cMENSAGEM=nIL
   cMENSAGEM:="Aguarde em processamento...."
endif

TRY
   oDlgHabla:ACONTROLS[1]:SETTEXT(cMENSAGEM)
catch e
//   HWG_DOEVENTS()
END
RETURN NIL

