"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createCompositeImage = createCompositeImage;
const admin = __importStar(require("firebase-admin"));
const https = __importStar(require("https"));
const http = __importStar(require("http"));
const sharp_1 = __importDefault(require("sharp"));
const v2_1 = require("firebase-functions/v2");
async function downloadImage(url) {
    return new Promise((resolve, reject) => {
        const protocol = url.startsWith('https') ? https : http;
        protocol.get(url, (res) => {
            const chunks = [];
            res.on('data', (chunk) => chunks.push(chunk));
            res.on('end', () => resolve(Buffer.concat(chunks)));
            res.on('error', reject);
        });
    });
}
function wrapText(text, maxCharsPerLine) {
    const words = text.split('');
    const lines = [];
    let currentLine = '';
    for (const char of words) {
        if (currentLine.length >= maxCharsPerLine) {
            lines.push(currentLine);
            currentLine = char;
        }
        else {
            currentLine += char;
        }
    }
    if (currentLine) {
        lines.push(currentLine);
    }
    return lines;
}
async function createCompositeImage(options) {
    const { backgroundUrl, text, author, quoteId } = options;
    try {
        v2_1.logger.info('Creating composite image', { quoteId, backgroundUrl });
        const backgroundBuffer = await downloadImage(backgroundUrl);
        const metadata = await (0, sharp_1.default)(backgroundBuffer).metadata();
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
        const textOverlay = Buffer.from(`<svg width="${width}" height="${height}">
        ${svgText}
      </svg>`);
        const compositeBuffer = await (0, sharp_1.default)(backgroundBuffer)
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
        v2_1.logger.info('Composite image created', { publicUrl });
        return publicUrl;
    }
    catch (error) {
        v2_1.logger.error('Failed to create composite image', error);
        return backgroundUrl;
    }
}
function escapeXml(unsafe) {
    return unsafe
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&apos;');
}
