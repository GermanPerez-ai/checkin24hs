# Dockerfile para checkin24hs-admin (React App)
FROM node:18-alpine AS builder

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar dependencias
RUN npm install

# Copiar el resto de los archivos
COPY . .

# Construir la aplicación React
RUN npm run build

# Etapa de producción - servir archivos estáticos
FROM node:18-alpine

WORKDIR /app

# Copiar los archivos construidos desde la etapa anterior
COPY --from=builder /app/build ./build

# Crear server.js usando printf para evitar problemas con comillas
RUN printf 'const http=require("http"),fs=require("fs"),path=require("path");const port=3000,buildDir=path.join(__dirname,"build");const mimeTypes={".html":"text/html",".js":"text/javascript",".css":"text/css",".json":"application/json",".png":"image/png",".jpg":"image/jpg",".jpeg":"image/jpeg",".gif":"image/gif",".svg":"image/svg+xml",".ico":"image/x-icon",".woff":"application/font-woff",".woff2":"application/font-woff2",".ttf":"application/font-ttf",".eot":"application/vnd.ms-fontobject"};const server=http.createServer((req,res)=>{let filePath=req.url==="/"?"/index.html":req.url;filePath=path.join(buildDir,filePath);const ext=path.extname(filePath).toLowerCase(),contentType=mimeTypes[ext]||"application/octet-stream";fs.readFile(filePath,(error,content)=>{if(error){if(error.code==="ENOENT"){const indexPath=path.join(buildDir,"index.html");fs.readFile(indexPath,(err,cont)=>{if(err){res.writeHead(500);res.end("Error loading index.html")}else{res.writeHead(200,{"Content-Type":"text/html"});res.end(cont,"utf-8")}})}else{res.writeHead(500);res.end("Server Error: "+error.code)}}else{res.writeHead(200,{"Content-Type":contentType});res.end(content,"utf-8")}})});server.listen(port,"0.0.0.0",()=>{console.log(`🚀 Server running at http://0.0.0.0:${port}/`)})' > server.js

# Exponer el puerto 3000
EXPOSE 3000

# Comando para iniciar el servidor
CMD ["node", "server.js"]
