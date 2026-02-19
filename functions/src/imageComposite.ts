import * as admin from 'firebase-admin';
import * as https from 'https';
import * as http from 'http';
import sharp from 'sharp';
import { logger } from 'firebase-functions/v2';

interface CompositeImageOptions {
  backgroundUrl: string;
  text: string;
  author?: string;
  quoteId: string;
}

async function downloadImage(url: string): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith('https') ? https : http;
    protocol.get(url, (res) => {
      const chunks: Buffer[] = [];
      res.on('data', (chunk) => chunks.push(chunk));
      res.on('end', () => resolve(Buffer.concat(chunks)));
      res.on('error', reject);
    });
  });
}

function wrapText(text: string, maxCharsPerLine: number): string[] {
  const words = text.split('');
  const lines: string[] = [];
  let currentLine = '';

  for (const char of words) {
    if (currentLine.length >= maxCharsPerLine) {
      lines.push(currentLine);
      currentLine = char;
    } else {
      currentLine += char;
    }
  }
  
  if (currentLine) {
    lines.push(currentLine);
  }

  return lines;
}

export async function createCompositeImage(
  options: CompositeImageOptions
): Promise<string> {
  const { backgroundUrl, text, author, quoteId } = options;

  try {
    logger.info('Creating composite image', { quoteId, backgroundUrl });

    const backgroundBuffer = await downloadImage(backgroundUrl);

    const metadata = await sharp(backgroundBuffer).metadata();
    const width = metadata.width || 1080;
    const height = metadata.height || 1920;

    const fontSize = Math.floor(width / 20);
    const lineHeight = Math.floor(fontSize * 1.6);
    const maxCharsPerLine = Math.floor(width / (fontSize * 0.6));

    const lines = wrapText(text, maxCharsPerLine);
    const textHeight = lines.length * lineHeight;
    const startY = Math.floor((height - textHeight) / 2);

    let svgText = '';
    lines.forEach((line, index) => {
      const y = startY + index * lineHeight;
      svgText += `<text x="50%" y="${y}" text-anchor="middle" fill="white" font-size="${fontSize}" font-family="sans-serif" font-weight="bold" stroke="black" stroke-width="3" paint-order="stroke">${escapeXml(line)}</text>`;
    });

    if (author) {
      const authorY = startY + textHeight + lineHeight;
      svgText += `<text x="50%" y="${authorY}" text-anchor="middle" fill="white" font-size="${Math.floor(fontSize * 0.8)}" font-family="sans-serif" font-style="italic" stroke="black" stroke-width="2" paint-order="stroke">- ${escapeXml(author)} -</text>`;
    }

    const textOverlay = Buffer.from(
      `<svg width="${width}" height="${height}">
        ${svgText}
      </svg>`
    );

    const compositeBuffer = await sharp(backgroundBuffer)
      .composite([
        {
          input: textOverlay,
          blend: 'over',
        },
      ])
      .jpeg({ quality: 85 })
      .toBuffer();

    const bucket = admin.storage().bucket();
    const fileName = `notifications/${quoteId}_${Date.now()}.jpg`;
    const file = bucket.file(fileName);

    await file.save(compositeBuffer, {
      metadata: {
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=86400',
      },
    });

    await file.makePublic();

    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;
    logger.info('Composite image created', { publicUrl });

    return publicUrl;
  } catch (error) {
    logger.error('Failed to create composite image', error);
    return backgroundUrl;
  }
}

function escapeXml(unsafe: string): string {
  return unsafe
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}
