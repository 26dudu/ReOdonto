import http from 'node:http';
import makeWASocket, {
  DisconnectReason,
  fetchLatestBaileysVersion,
  useMultiFileAuthState,
} from '@whiskeysockets/baileys';
import pino from 'pino';
import QRCode from 'qrcode';

const N8N_URL = process.env.N8N_WEBHOOK_URL || 'http://localhost:5678/webhook/whatsapp';
const PORTA_QR = Number(process.env.PORTA_QR || 3100);
function chaveDoNumero(numero) {
  const digitos = numero.replace(/\D/g, '').replace(/^55/, '');
  return digitos.slice(0, 2) + digitos.slice(-8);
}

const PERMITIDOS = (process.env.WHATSAPP_NUMEROS_PERMITIDOS || '')
  .split(',')
  .filter(Boolean)
  .map(chaveDoNumero);

const NUMERO_PAREAMENTO = (process.env.WHATSAPP_NUMERO_DENTISTA || '').replace(/\D/g, '');
const CONVERSAS = new Map();
const VALIDADE_CONVERSA_MS = 15 * 60 * 1000;
const MAX_FALAS = 8;
const STATUS_FINAIS = [
  'confirmado',
  'encaixado',
  'cancelado',
  'nao_encontrado',
  'adiantado',
  'oferta_recusada',
  'oferta_expirada',
  'oferta_indisponivel',
  'sem_oferta',
];
const CHAVE_API = process.env.INTEGRACAO_API_KEY || '';

function registrarFala(telefone, quem, texto) {
  const chave = chaveDoNumero(telefone);
  const agora = Date.now();
  const atuais = (CONVERSAS.get(chave) || []).filter((f) => agora - f.em < VALIDADE_CONVERSA_MS);
  atuais.push({ quem, texto, em: agora });
  const recentes = atuais.slice(-MAX_FALAS);
  CONVERSAS.set(chave, recentes);
  return recentes;
}

function limparConversa(telefone) {
  CONVERSAS.delete(chaveDoNumero(telefone));
}

let sockAtual = null;
let qrAtual = null;
let codigoPareamento = null;
let conectado = false;

function lerCorpo(req) {
  return new Promise((resolve, reject) => {
    let dados = '';
    req.on('data', (parte) => {
      dados += parte;
      if (dados.length > 100000) req.destroy();
    });
    req.on('end', () => resolve(dados));
    req.on('error', reject);
  });
}

async function resolverJid(telefone) {
  let digitos = telefone.replace(/\D/g, '');
  if (!digitos.startsWith('55') && (digitos.length === 10 || digitos.length === 11)) {
    digitos = `55${digitos}`;
  }
  const candidatos = [digitos];
  if (digitos.length === 13) candidatos.push(digitos.slice(0, 4) + digitos.slice(5));
  if (digitos.length === 12) candidatos.push(`${digitos.slice(0, 4)}9${digitos.slice(4)}`);
  for (const candidato of candidatos) {
    const [resultado] = (await sockAtual.onWhatsApp(candidato)) || [];
    if (resultado?.exists) return resultado.jid;
  }
  return null;
}

async function tratarEnvio(req, res) {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  const responder = (codigo, corpo) => {
    res.statusCode = codigo;
    res.end(JSON.stringify(corpo));
  };
  if (!CHAVE_API || req.headers['x-api-key'] !== CHAVE_API) {
    return responder(401, { erro: 'Chave de API inválida' });
  }
  if (!conectado || !sockAtual) {
    return responder(503, { erro: 'WhatsApp não conectado' });
  }
  try {
    const { telefone, mensagem } = JSON.parse(await lerCorpo(req));
    if (!telefone || !mensagem) return responder(400, { erro: 'telefone e mensagem são obrigatórios' });
    if (!PERMITIDOS.includes(chaveDoNumero(telefone))) {
      console.log(`Envio recusado para ${telefone} (não está em WHATSAPP_NUMEROS_PERMITIDOS)`);
      return responder(403, { erro: 'Número fora da lista de permitidos' });
    }
    const jid = await resolverJid(telefone);
    if (!jid) return responder(404, { erro: 'Número sem WhatsApp' });
    await sockAtual.sendMessage(jid, { text: mensagem });
    registrarFala(telefone, 'Recepcionista', mensagem);
    console.log(`[envio -> ${telefone}] ${mensagem}`);
    return responder(200, { ok: true });
  } catch (erro) {
    console.error('Falha ao enviar:', erro.message);
    return responder(500, { erro: 'Falha ao enviar' });
  }
}

const servidor = http.createServer(async (req, res) => {
  if (req.method === 'POST' && req.url === '/enviar') {
    await tratarEnvio(req, res);
    return;
  }
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  if (conectado) {
    res.end('<h2>WhatsApp conectado.</h2>');
    return;
  }
  if (!qrAtual) {
    res.setHeader('Refresh', '2');
    res.end('<h2>Aguardando o QR code...</h2>');
    return;
  }
  res.setHeader('Refresh', '5');
  if (codigoPareamento) {
    res.end(`<h2>Código de pareamento</h2><p style="font-size:48px;letter-spacing:6px"><b>${codigoPareamento}</b></p><p>No celular do dentista: WhatsApp, Aparelhos conectados, Conectar um aparelho, Conectar com número de telefone, e digite o código.</p>`);
    return;
  }
  const imagem = await QRCode.toDataURL(qrAtual, { width: 360 });
  res.end(`<h2>Escaneie com o WhatsApp do número do dentista</h2><p>WhatsApp, Aparelhos conectados, Conectar um aparelho</p><img src="${imagem}">`);
});
servidor.listen(PORTA_QR, '127.0.0.1', () => {
  console.log(`QR code em http://localhost:${PORTA_QR}`);
});

function extrairTexto(mensagem) {
  return (
    mensagem?.conversation ||
    mensagem?.extendedTextMessage?.text ||
    ''
  ).trim();
}

async function chamarN8n(corpo) {
  const resposta = await fetch(N8N_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(corpo),
  });
  if (!resposta.ok) {
    throw new Error(`n8n respondeu ${resposta.status}`);
  }
  return resposta.json();
}

async function iniciar() {
  const { state, saveCreds } = await useMultiFileAuthState('auth');
  const { version } = await fetchLatestBaileysVersion();
  const sock = makeWASocket({
    version,
    auth: state,
    logger: pino({ level: 'silent' }),
    browser: ['ReOdonto', 'Chrome', '1.0'],
  });

  sockAtual = sock;
  sock.ev.on('creds.update', saveCreds);

  sock.ev.on('connection.update', ({ connection, lastDisconnect, qr }) => {
    if (qr) {
      qrAtual = qr;
      if (NUMERO_PAREAMENTO && !state.creds.registered && !codigoPareamento) {
        sock.requestPairingCode(NUMERO_PAREAMENTO)
          .then((codigo) => {
            codigoPareamento = codigo.match(/.{1,4}/g).join('-');
            console.log(`Código de pareamento: ${codigoPareamento}`);
          })
          .catch((erro) => console.error('Falha ao gerar código:', erro.message));
      }
    }
    if (connection === 'open') {
      conectado = true;
      qrAtual = null;
      codigoPareamento = null;
      console.log('WhatsApp conectado.');
    }
    if (connection === 'close') {
      conectado = false;
      qrAtual = null;
      codigoPareamento = null;
      const codigo = lastDisconnect?.error?.output?.statusCode;
      if (codigo === DisconnectReason.loggedOut) {
        console.log('Sessão encerrada. Apague a pasta auth e escaneie o QR de novo.');
        return;
      }
      console.log(`Conexão caiu (código ${codigo}: ${lastDisconnect?.error?.message}), reconectando em 5s...`);
      setTimeout(iniciar, 5000);
    }
  });

  sock.ev.on('messages.upsert', async ({ messages, type }) => {
    if (type !== 'notify') return;
    for (const msg of messages) {
      const jid = msg.key.remoteJid || '';
      if (msg.key.fromMe || jid.endsWith('@g.us') || jid === 'status@broadcast') continue;

      const texto = extrairTexto(msg.message);
      if (!texto) continue;

      const origem = msg.key.remoteJidAlt || jid;
      const telefone = origem.split('@')[0].split(':')[0].replace(/\D/g, '');

      if (!PERMITIDOS.includes(chaveDoNumero(telefone))) {
        console.log(`Ignorada mensagem de ${telefone} (não está em WHATSAPP_NUMEROS_PERMITIDOS)`);
        continue;
      }

      console.log(`[${telefone}] ${texto}`);
      const historico = registrarFala(telefone, 'Paciente', texto);
      try {
        const resultado = await chamarN8n({
          mensagem: historico.map((f) => `${f.quem}: ${f.texto}`).join('\n'),
          nome: '',
          telefone,
        });
        const resposta = resultado.resposta || resultado.mensagem;
        if (resposta) {
          await sock.sendMessage(jid, { text: resposta });
          console.log(`-> ${resultado.status}: ${resposta}`);
          if (STATUS_FINAIS.includes(resultado.status)) {
            limparConversa(telefone);
          } else {
            registrarFala(telefone, 'Recepcionista', resposta);
          }
        }
      } catch (erro) {
        console.error('Falha ao processar:', erro.message);
        await sock.sendMessage(jid, {
          text: 'Não consegui processar seu pedido agora. Tente novamente em instantes.',
        });
      }
    }
  });
}

iniciar();
