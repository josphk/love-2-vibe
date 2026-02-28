# Module 13: Build, Ship & What's Next

**Part of:** [R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)
**Estimated study time:** 4–8 hours
**Prerequisites:** Any prior modules

---

## Overview

You've been building things this entire roadmap. Now you ship them.

The gap between "works on my machine" and "people are playing this" is where 90% of indie projects die. Not because shipping is hard — it's actually straightforward — but because developers treat it as an afterthought. They optimize endlessly, polish indefinitely, and never click "deploy." This module is about closing that gap. You'll compress your assets, split your bundles, add a loading screen, wrap everything in an error boundary, and push it live where real humans can click on it.

Shipping is a skill. Like any skill, it gets easier with practice. The first deploy feels scary. The tenth feels like nothing. You want to get to the tenth as fast as possible.

This module also looks forward. You've built a solid foundation in R3F game development — where do you take it next? WebXR? Native desktop apps? Mobile? Game jams? We'll survey the landscape so you can pick your next path with confidence.

Your mini-project: take the best thing you've built in any previous module, polish it with a loading screen, compressed assets, responsive design, and error handling, then ship it to Vercel or itch.io. By the end of this module, you'll have a URL you can send to anyone.

---

## 1. The Shipping Mindset

### Done Is Better Than Perfect

Here's the uncomfortable truth: nobody cares about your game until they can play it. The most beautiful, technically impressive project in the world has zero value sitting on your local machine. A janky prototype on a live URL has more value because people can experience it, give feedback, and validate your ideas.

The indie game graveyard is full of projects that were "almost done." Almost done is not done. Ship early, ship often, ship ugly if you have to.

### Scope Ruthlessly

Before you ship, ruthlessly cut scope. Ask yourself:

- Does the core gameplay loop work? Ship it.
- Are there bugs in edge cases? Ship it, fix them later.
- Is the UI ugly? Ship it, pretty it up in the next version.
- Are you missing "one more feature"? Ship without it.

The only things that genuinely block shipping are: crashes on load, the core mechanic being broken, and content that could harm users. Everything else is a "nice to have" for v1.1.

### The Indie Game Shipping Checklist

Before you deploy, run through this checklist:

| Check | Why |
|-------|-----|
| Game loads without errors | Obvious |
| Core gameplay loop works | Players need to understand what to do |
| Loading screen exists | Users shouldn't stare at a blank page |
| Error boundary catches crashes | WebGL failures shouldn't show a white screen |
| Assets are compressed | 50MB load = nobody waits |
| Works on mobile (or explicitly doesn't) | Set expectations |
| Has a title/start screen | First impressions matter |
| Performance is acceptable on mid-range hardware | Not just your dev machine |

That's it. That's the bar. Everything beyond this is polish for the next release.

---

## 2. Vite Production Build

### The Default Build

Vite's production build already does a lot: minification, tree-shaking, and asset hashing. Start with the basics:

```bash
npm run build
```

This creates a `dist/` folder with your production assets. But for a Three.js/R3F project, the defaults aren't enough. Three.js is massive, and without manual intervention your main bundle will be enormous.

### Analyzing Bundle Size

Before optimizing, measure. Install vite-bundle-visualizer to see exactly where your bytes are going:

```bash
npm install -D vite-bundle-visualizer
npx vite-bundle-visualizer
```

This generates an interactive treemap showing every module in your bundle. You'll almost certainly see Three.js dominating — typically 600KB+ minified. That's your target.

### Optimized Vite Config

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  build: {
    // Target modern browsers only — no legacy polyfills
    target: 'esnext',

    // Increase chunk warning limit for Three.js (it's big, that's ok)
    chunkSizeWarningLimit: 800,

    rollupOptions: {
      output: {
        // Manual chunks: split Three.js and React into separate cacheable files
        manualChunks: {
          three: ['three'],
          'react-vendor': ['react', 'react-dom'],
          'r3f-vendor': [
            '@react-three/fiber',
            '@react-three/drei',
          ],
        },
      },
    },

    // Enable source maps for debugging production issues (optional)
    sourcemap: false,

    // Minification — esbuild is default and fastest
    minify: 'esbuild',
  },

  // Optimize dependency pre-bundling
  optimizeDeps: {
    include: ['three', '@react-three/fiber', '@react-three/drei'],
  },
})
```

### Why Manual Chunks Matter

Without `manualChunks`, Vite bundles Three.js into your main chunk. That means every time you change a single line of game code, users re-download the entire Three.js library. With manual chunks:

- `three.js` chunk (~600KB) is cached separately — users download it once
- `react-vendor.js` chunk (~40KB) is also cached separately
- Your game code chunk is small and changes frequently — that's fine, it's the only thing users re-download

### Compression Plugin

For an extra 60-70% size reduction on text assets, add gzip/brotli compression:

```bash
npm install -D vite-plugin-compression
```

```typescript
// vite.config.ts
import compression from 'vite-plugin-compression'

export default defineConfig({
  plugins: [
    react(),
    compression({ algorithm: 'gzip' }),
    compression({ algorithm: 'brotliCompress' }),
  ],
  // ... rest of config
})
```

Most CDNs and hosting platforms (Vercel, Netlify) handle compression automatically, so this is optional. But if you're self-hosting, it's essential.

---

## 3. Asset Compression

### The Asset Problem

A single uncompressed GLTF model can easily be 10–50MB. A 4K texture is 16MB. If your game loads 100MB of assets, you've already lost most of your audience. Mobile users will bounce immediately. Even on fast connections, the loading screen will test patience.

The goal: get your total asset payload under 5MB for the initial load, under 20MB total.

### Draco Compression for Geometry

Draco is Google's open-source geometry compression library. It typically reduces GLTF file sizes by 90% or more. That 10MB model becomes 500KB.

Install the CLI tools:

```bash
npm install -g gltf-transform-cli
npm install -g @gltf-transform/cli
```

Compress a single model:

```bash
npx gltf-transform draco input.glb output.glb
```

### Using Draco-Compressed Models in R3F

R3F/drei handles Draco decompression automatically with `useGLTF`, but you need to tell it where the Draco decoder lives:

```tsx
import { useGLTF } from '@react-three/drei'

// Option 1: Use the CDN-hosted decoder (easiest)
useGLTF.preload('/models/spaceship.glb')

export function Spaceship() {
  const { scene } = useGLTF('/models/spaceship.glb')
  return <primitive object={scene} />
}
```

drei's `useGLTF` automatically detects Draco-compressed files and loads the decoder from a CDN. If you need to self-host the decoder (for offline/PWA use):

```tsx
import { DRACOLoader } from 'three/examples/jsm/loaders/DRACOLoader.js'
import { useLoader } from '@react-three/fiber'
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js'

const dracoLoader = new DRACOLoader()
dracoLoader.setDecoderPath('/draco/')

export function Model() {
  const gltf = useLoader(GLTFLoader, '/models/spaceship.glb', (loader) => {
    loader.setDRACOLoader(dracoLoader)
  })
  return <primitive object={gltf.scene} />
}
```

### KTX2/Basis Texture Compression

Textures are often the biggest payload. KTX2 with Basis Universal compression gives you GPU-native compressed textures that are smaller on disk AND use less GPU memory.

```bash
# Convert a PNG texture to KTX2 with Basis compression
npx gltf-transform etc1s input.glb output.glb
# Or for higher quality:
npx gltf-transform uastc input.glb output.glb
```

| Format | Use Case | Quality | Size |
|--------|----------|---------|------|
| ETC1S | Diffuse/albedo textures, lower quality OK | Medium | Smallest |
| UASTC | Normal maps, anything quality-critical | High | ~2x ETC1S |

### Automated Compression Script

Create a script to compress all your assets in one go:

```bash
#!/bin/bash
# scripts/compress-assets.sh

INPUT_DIR="assets/models/raw"
OUTPUT_DIR="public/models"

mkdir -p "$OUTPUT_DIR"

for file in "$INPUT_DIR"/*.glb; do
  filename=$(basename "$file")
  echo "Compressing $filename..."

  npx gltf-transform draco "$file" "/tmp/$filename"
  npx gltf-transform etc1s "/tmp/$filename" "$OUTPUT_DIR/$filename"

  original_size=$(wc -c < "$file")
  compressed_size=$(wc -c < "$OUTPUT_DIR/$filename")
  ratio=$(echo "scale=1; $compressed_size * 100 / $original_size" | bc)

  echo "  $original_size -> $compressed_size bytes (${ratio}% of original)"
done

echo "Done! All compressed models in $OUTPUT_DIR"
```

```bash
chmod +x scripts/compress-assets.sh
./scripts/compress-assets.sh
```

### The gltf-transform Pipeline

For more control, use gltf-transform's full pipeline:

```bash
# Full optimization pipeline
npx gltf-transform dedup input.glb output.glb     # Remove duplicate data
npx gltf-transform flatten output.glb output.glb   # Flatten node hierarchy
npx gltf-transform prune output.glb output.glb     # Remove unused resources
npx gltf-transform resize output.glb output.glb \
  --width 1024 --height 1024                        # Downscale textures
npx gltf-transform draco output.glb output.glb      # Draco compression
npx gltf-transform etc1s output.glb output.glb      # Texture compression
```

Run `dedup` and `prune` first — you'd be surprised how much dead data accumulates in GLTF files exported from Blender.

---

## 4. Lazy Loading

### Why Lazy Load?

Your game might have a main menu, a gameplay scene, a settings screen, and a game-over screen. Loading all of them upfront wastes bandwidth and increases initial load time. Lazy loading means: only load what you need, when you need it.

### React.lazy for Scene Code Splitting

Split heavy scenes into separate chunks that load on demand:

```tsx
// src/App.tsx
import { Suspense, lazy, useState } from 'react'
import { Canvas } from '@react-three/fiber'
import { LoadingScreen } from './components/LoadingScreen'

// These chunks only download when the component is first rendered
const MainMenu = lazy(() => import('./scenes/MainMenu'))
const GameScene = lazy(() => import('./scenes/GameScene'))
const GameOver = lazy(() => import('./scenes/GameOver'))

type GameState = 'menu' | 'playing' | 'gameover'

export default function App() {
  const [gameState, setGameState] = useState<GameState>('menu')

  return (
    <Canvas camera={{ position: [0, 5, 10] }}>
      <Suspense fallback={<LoadingScreen />}>
        {gameState === 'menu' && (
          <MainMenu onStart={() => setGameState('playing')} />
        )}
        {gameState === 'playing' && (
          <GameScene onGameOver={() => setGameState('gameover')} />
        )}
        {gameState === 'gameover' && (
          <GameOver onRestart={() => setGameState('menu')} />
        )}
      </Suspense>
    </Canvas>
  )
}
```

### Progressive Asset Loading

For large scenes, load assets progressively instead of blocking on everything:

```tsx
import { useGLTF } from '@react-three/drei'
import { Suspense } from 'react'

// Low-res placeholder that loads instantly
function PlaceholderShip() {
  return (
    <mesh>
      <boxGeometry args={[2, 0.5, 3]} />
      <meshStandardMaterial color="#335577" wireframe />
    </mesh>
  )
}

// High-res model that loads in the background
function DetailedShip() {
  const { scene } = useGLTF('/models/spaceship-hd.glb')
  return <primitive object={scene} />
}

// Combine them: show placeholder instantly, swap when HD loads
export function Ship() {
  return (
    <Suspense fallback={<PlaceholderShip />}>
      <DetailedShip />
    </Suspense>
  )
}
```

### Preloading Critical Assets

Preload models you know you'll need soon, before the user triggers them:

```tsx
import { useGLTF } from '@react-three/drei'

// Preload during idle time — the model will be cached when needed
useGLTF.preload('/models/spaceship.glb')
useGLTF.preload('/models/asteroid.glb')
useGLTF.preload('/models/explosion.glb')
```

Call `preload` at the module level (outside components) for assets needed in the current scene, or trigger it during the menu screen for assets needed in gameplay.

---

## 5. Performance Audit

### Target Metrics

Before you ship, know your performance targets:

| Metric | Target | Why |
|--------|--------|-----|
| FPS | 60fps desktop, 30fps mobile | Below this, gameplay feels sluggish |
| Initial load | < 3 seconds on 4G | Users abandon at 3s |
| Total bundle | < 2MB JS (gzipped) | Keeps load fast |
| Total assets | < 20MB | Reasonable for a web game |
| Largest chunk | < 500KB (gzipped) | Avoid blocking the main thread |
| Time to interactive | < 5 seconds | User should be doing something quickly |

### Using r3f-perf

`r3f-perf` gives you real-time performance metrics inside your scene:

```bash
npm install r3f-perf
```

```tsx
import { Perf } from 'r3f-perf'

function App() {
  return (
    <Canvas>
      {/* Only show in development */}
      {import.meta.env.DEV && (
        <Perf
          position="top-left"
          showGraph
          minimal={false}
        />
      )}
      {/* ... your scene */}
    </Canvas>
  )
}
```

r3f-perf shows you FPS, draw calls, triangles, GPU memory, and more. Watch for:

- **Draw calls > 100**: You need instancing or mesh merging
- **Triangles > 1M**: Simplify geometry or use LOD
- **Frame time > 16ms**: You're dropping below 60fps

### Lighthouse Audit

Run a Lighthouse audit on your production build:

```bash
npm run build
npm run preview
# Open Chrome DevTools > Lighthouse > Run audit
```

Focus on:
- **Performance score**: Aim for 70+ (web games are inherently heavy, 90+ is rare)
- **Largest Contentful Paint**: Should be < 2.5s
- **Total Blocking Time**: Should be < 300ms
- **Cumulative Layout Shift**: Should be < 0.1

### Mobile Performance

Mobile GPUs are 5–10x weaker than desktop GPUs. If you care about mobile:

```tsx
import { useThree } from '@react-three/fiber'
import { useDetectGPU } from '@react-three/drei'

function AdaptiveQuality() {
  const GPUTier = useDetectGPU()

  // Tier 0-1: mobile/weak, Tier 2: mid, Tier 3: high-end
  const isMobile = GPUTier.tier <= 1

  return (
    <Canvas
      dpr={isMobile ? [1, 1.5] : [1, 2]}
      shadows={!isMobile}
    >
      {/* Reduce particle counts, disable post-processing, etc. */}
    </Canvas>
  )
}
```

---

## 6. Error Boundaries

### Why You Need Error Boundaries

Three.js and WebGL can fail in ways React doesn't expect: unsupported GPU features, context loss, out-of-memory on mobile, shader compilation failures. Without an error boundary, any of these kills your entire app with a blank white screen.

### R3F Error Boundary

```tsx
// src/components/ErrorBoundary.tsx
import { Component, type ReactNode } from 'react'

interface Props {
  children: ReactNode
  fallback?: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export class R3FErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // Log to your error reporting service
    console.error('R3F Error:', error, errorInfo)

    // Optional: send to Sentry, LogRocket, etc.
    // reportError(error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback ?? (
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          height: '100vh',
          backgroundColor: '#1a1a2e',
          color: '#e0e0e0',
          fontFamily: 'system-ui, sans-serif',
          padding: '2rem',
          textAlign: 'center',
        }}>
          <h1 style={{ fontSize: '2rem', marginBottom: '1rem' }}>
            Something went wrong
          </h1>
          <p style={{ fontSize: '1.1rem', opacity: 0.7, maxWidth: '500px' }}>
            The 3D engine encountered an error. This usually means your browser
            or device doesn't support a required feature.
          </p>
          <button
            onClick={() => window.location.reload()}
            style={{
              marginTop: '2rem',
              padding: '0.75rem 2rem',
              fontSize: '1rem',
              backgroundColor: '#4a9eff',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer',
            }}
          >
            Reload Page
          </button>
          {import.meta.env.DEV && this.state.error && (
            <pre style={{
              marginTop: '2rem',
              padding: '1rem',
              backgroundColor: '#0d0d1a',
              borderRadius: '8px',
              fontSize: '0.85rem',
              maxWidth: '600px',
              overflow: 'auto',
              textAlign: 'left',
            }}>
              {this.state.error.message}
            </pre>
          )}
        </div>
      )
    }

    return this.props.children
  }
}
```

### Wrapping the Canvas

```tsx
// src/App.tsx
import { Canvas } from '@react-three/fiber'
import { R3FErrorBoundary } from './components/ErrorBoundary'

export default function App() {
  return (
    <R3FErrorBoundary>
      <Canvas camera={{ position: [0, 5, 10] }}>
        {/* Your scene */}
      </Canvas>
    </R3FErrorBoundary>
  )
}
```

### WebGL Context Loss Handling

WebGL contexts can be lost when the GPU is overwhelmed or the browser reclaims resources. Handle this explicitly:

```tsx
import { useThree } from '@react-three/fiber'
import { useEffect } from 'react'

function ContextLossHandler() {
  const { gl } = useThree()

  useEffect(() => {
    const canvas = gl.domElement

    const handleContextLost = (event: Event) => {
      event.preventDefault()
      console.warn('WebGL context lost. Attempting to restore...')
    }

    const handleContextRestored = () => {
      console.log('WebGL context restored.')
      // Re-initialize any resources that were lost
    }

    canvas.addEventListener('webglcontextlost', handleContextLost)
    canvas.addEventListener('webglcontextrestored', handleContextRestored)

    return () => {
      canvas.removeEventListener('webglcontextlost', handleContextLost)
      canvas.removeEventListener('webglcontextrestored', handleContextRestored)
    }
  }, [gl])

  return null
}
```

---

## 7. Deploying to Vercel/Netlify

### Vercel Deployment

Vercel is the simplest path from code to URL. If your project is on GitHub:

```bash
# Install the Vercel CLI
npm install -g vercel

# Deploy from your project directory
vercel

# Or for production:
vercel --prod
```

That's literally it. Vercel auto-detects Vite projects and configures everything. But for games with large static assets, you'll want a custom config:

```json
// vercel.json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/models/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/(.*).js",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=0, must-revalidate"
        }
      ]
    }
  ]
}
```

### Why Cache Headers Matter

Vite hashes your built assets (e.g., `index-a1b2c3d4.js`). The hash changes when the content changes. This means you can safely tell browsers to cache these files forever — they'll automatically get the new version because the filename changes. Without proper cache headers, users re-download your entire Three.js bundle on every visit. That's 600KB+ wasted on every page load.

### Netlify Deployment

Similar to Vercel, but with a `netlify.toml` file:

```toml
# netlify.toml
[build]
  command = "npm run build"
  publish = "dist"

[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/models/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/*.js"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

### Environment Variables

If your game uses any API keys or configuration that varies by environment:

```bash
# .env.production
VITE_ANALYTICS_ID=UA-XXXXXXX
VITE_API_URL=https://api.yourgame.com
```

Access them in code with `import.meta.env.VITE_ANALYTICS_ID`. The `VITE_` prefix is required — Vite only exposes variables with this prefix to the client bundle for security.

---

## 8. Deploying to itch.io

### Why itch.io?

itch.io is the largest indie game marketplace. It has a massive community of players looking specifically for indie games. Your web game runs directly in the browser — no downloads. It's free to publish, and itch.io takes zero cut by default (you choose what to pay them).

### Packaging for itch.io

itch.io wants a zip file containing your built game:

```bash
# Build the project
npm run build

# Zip the dist folder
cd dist
zip -r ../my-game.zip .
cd ..
```

### The Upload Process

1. Create an account at [itch.io](https://itch.io)
2. Go to Dashboard > Create new project
3. Set "Kind of project" to **HTML**
4. Upload your `my-game.zip`
5. Check **"This file will be played in the browser"**
6. Set the viewport dimensions (e.g., 960x640 or 1280x720)
7. Check **"Enable scrollbars"** — leave unchecked for fullscreen games
8. Check **"Fullscreen button"** — always enable this for 3D games
9. Click **Save & view page**

### itch.io-Specific Considerations

**Viewport size:** itch.io embeds your game in an iframe. Make sure your CSS handles the container sizing properly. The `100vh`/`100vw` approach works well inside the iframe.

**Shared array buffer:** Some Three.js features (like Draco decompression with WASM threads) require `SharedArrayBuffer`, which needs specific headers. itch.io doesn't support these headers. Use the non-threaded Draco decoder or pre-decompress your models.

**Mobile support:** itch.io has a mobile audience. If your game doesn't support mobile, say so in the description. If it does, test it in the itch.io mobile browser.

```tsx
// Detect if running in an iframe (itch.io embed)
const isIframe = window.self !== window.top

// Adjust UI accordingly — smaller fonts, bigger buttons for touch
```

---

## 9. PWA (Progressive Web App)

### Why PWA?

A PWA turns your web game into something that feels like a native app: installable, works offline, has a splash screen, and lives on the user's home screen. For a web game, this means players can install it and launch it like any other app — no app store required.

### Manifest File

```json
// public/manifest.json
{
  "name": "My R3F Game",
  "short_name": "R3F Game",
  "description": "An awesome 3D game built with React Three Fiber",
  "start_url": "/",
  "display": "fullscreen",
  "orientation": "landscape",
  "background_color": "#000000",
  "theme_color": "#1a1a2e",
  "icons": [
    {
      "src": "/icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-512-maskable.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ]
}
```

Link it in your `index.html`:

```html
<!-- index.html -->
<head>
  <link rel="manifest" href="/manifest.json" />
  <meta name="theme-color" content="#1a1a2e" />
  <link rel="apple-touch-icon" href="/icons/icon-192.png" />
</head>
```

### Service Worker with Vite

Use `vite-plugin-pwa` to generate a service worker automatically:

```bash
npm install -D vite-plugin-pwa
```

```typescript
// vite.config.ts
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: [
        'favicon.ico',
        'icons/*.png',
        'models/*.glb',
      ],
      manifest: {
        name: 'My R3F Game',
        short_name: 'R3F Game',
        description: 'An awesome 3D game built with React Three Fiber',
        theme_color: '#1a1a2e',
        background_color: '#000000',
        display: 'fullscreen',
        orientation: 'landscape',
        icons: [
          {
            src: '/icons/icon-192.png',
            sizes: '192x192',
            type: 'image/png',
          },
          {
            src: '/icons/icon-512.png',
            sizes: '512x512',
            type: 'image/png',
          },
        ],
      },
      workbox: {
        // Cache game assets aggressively
        runtimeCaching: [
          {
            urlPattern: /\.(?:glb|gltf|hdr|ktx2)$/,
            handler: 'CacheFirst',
            options: {
              cacheName: 'game-assets',
              expiration: {
                maxEntries: 50,
                maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
              },
            },
          },
          {
            urlPattern: /\.(?:png|jpg|jpeg|webp)$/,
            handler: 'CacheFirst',
            options: {
              cacheName: 'image-assets',
              expiration: {
                maxEntries: 100,
                maxAgeSeconds: 30 * 24 * 60 * 60,
              },
            },
          },
        ],
      },
    }),
  ],
})
```

### Testing the PWA

```bash
npm run build
npm run preview
```

Open Chrome DevTools > Application tab. You should see:
- **Manifest** section showing your app info
- **Service Workers** section showing the registered worker
- **Cache Storage** showing cached assets

Click "Install" in Chrome's address bar to test the install flow. On mobile, you'll get "Add to Home Screen."

---

## 10. WebXR Introduction

### What WebXR Gives You

WebXR lets your Three.js/R3F scene run in VR headsets and AR-capable devices — directly in the browser. No app store, no installation, just a URL. The `@react-three/xr` library makes this surprisingly easy with R3F.

```bash
npm install @react-three/xr
```

### Basic VR Setup

```tsx
import { Canvas } from '@react-three/fiber'
import { XR, createXRStore } from '@react-three/xr'

const store = createXRStore()

export default function App() {
  return (
    <>
      <button onClick={() => store.enterVR()}>
        Enter VR
      </button>
      <Canvas>
        <XR store={store}>
          <ambientLight intensity={0.5} />
          <directionalLight position={[5, 5, 5]} />
          <mesh position={[0, 1.5, -2]}>
            <boxGeometry />
            <meshStandardMaterial color="hotpink" />
          </mesh>
        </XR>
      </Canvas>
    </>
  )
}
```

### AR Mode

```tsx
<button onClick={() => store.enterAR()}>
  Enter AR
</button>
```

AR mode uses the device camera as the background and overlays your 3D objects on the real world. It works on supported mobile browsers (Chrome on Android, Safari on iOS with limitations).

### Hand Tracking

```tsx
import { XR, XROrigin, useXRInputSourceState } from '@react-three/xr'

function Hands() {
  const leftHand = useXRInputSourceState('hand', 'left')
  const rightHand = useXRInputSourceState('hand', 'right')

  // Hand tracking data is available when the headset supports it
  // Use it for gesture-based interactions
  return null
}
```

### The XR Session Lifecycle

1. **Request session**: User clicks "Enter VR/AR" button (must be user-initiated)
2. **Session starts**: The Canvas enters immersive mode, headset displays the scene
3. **Frame loop**: `useFrame` continues working normally, but now renders for each eye
4. **Session ends**: User exits VR/AR, Canvas returns to normal rendering

WebXR is a deep topic. This is just the entry point to show you it's accessible from R3F. If you want to build VR/AR experiences, explore the `@react-three/xr` documentation and examples in depth.

---

## 11. Future Paths

### You've Built a Foundation

If you've worked through this roadmap, you have a real skill set: React, Three.js, R3F, physics, shaders, audio, UI, ECS patterns, and now deployment. That's not "tutorial knowledge" — that's the ability to build and ship things. Here's where you can take it.

### Bigger Games

Scale up what you've already built. Multi-level games, save systems, procedural generation, multiplayer. The patterns you've learned compose: ECS for entity management, Zustand for state, Rapier for physics, R3F for rendering. Bigger games are the same pieces, assembled into larger structures.

### Native Desktop Apps

Wrap your web game in Electron or Tauri to ship as a native desktop app:

```bash
# Tauri (Rust-based, smaller binary, better performance)
npm install -D @tauri-apps/cli
npx tauri init
npx tauri build
```

Tauri is the better choice for games — smaller bundle, better performance, and you can access native APIs for things like file system saves, system tray icons, and hardware acceleration.

### Mobile with React Native + R3F

`@react-three/fiber` has a React Native renderer. Your R3F components work on mobile with minimal changes:

```bash
npm install @react-three/fiber expo-gl expo-three
```

The same `<Canvas>`, `useFrame`, and component patterns work. The main differences are performance budgets (mobile GPUs are weaker) and input handling (touch instead of mouse).

### Advanced AI Integration

Integrate AI into your games: procedural content generation with LLMs, NPC dialogue systems, AI-driven difficulty adjustment, procedural quest generation. The web platform gives you easy access to API-based AI services.

### Game Jams

Game jams are the single best way to grow as a game developer. You have a strict deadline (usually 48–72 hours), a theme, and you must ship. Your R3F skills give you an edge — most jam participants use Unity or Godot, so a polished web game that runs in the browser stands out.

Popular jams to watch for:
- **Ludum Dare** (every 6 months, massive community)
- **Global Game Jam** (annual, worldwide)
- **js13kGames** (JavaScript-only, 13KB size limit — extreme constraint)
- **itch.io jams** (constantly running, every theme imaginable)

### Contributing to the Poimandres Ecosystem

The libraries you've been using — R3F, drei, Rapier bindings, zustand — are all open source under the [Poimandres](https://github.com/pmndrs) collective. Contributing is one of the best ways to deepen your understanding:

- Fix a bug in drei
- Add a new helper component
- Improve documentation
- Create examples

The Poimandres Discord is active and welcoming. Many contributors started exactly where you are.

---

## Code Walkthrough: Ship a Polished Project

Let's walk through every piece of shipping infrastructure you need. This is a complete reference you can copy into any R3F project.

### Step 1: Optimized Vite Config

```typescript
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.ico', 'icons/*.png'],
      manifest: {
        name: 'My R3F Game',
        short_name: 'R3F Game',
        theme_color: '#1a1a2e',
        background_color: '#000000',
        display: 'fullscreen',
        orientation: 'landscape',
        icons: [
          { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png' },
        ],
      },
      workbox: {
        runtimeCaching: [
          {
            urlPattern: /\.(?:glb|gltf|hdr|ktx2)$/,
            handler: 'CacheFirst',
            options: {
              cacheName: 'game-assets',
              expiration: { maxEntries: 50, maxAgeSeconds: 2592000 },
            },
          },
        ],
      },
    }),
  ],
  build: {
    target: 'esnext',
    chunkSizeWarningLimit: 800,
    rollupOptions: {
      output: {
        manualChunks: {
          three: ['three'],
          'react-vendor': ['react', 'react-dom'],
          'r3f-vendor': ['@react-three/fiber', '@react-three/drei'],
        },
      },
    },
  },
})
```

### Step 2: Asset Compression Script

```bash
#!/bin/bash
# scripts/compress-assets.sh
set -e

echo "=== Asset Compression Pipeline ==="

INPUT_DIR="${1:-assets/models/raw}"
OUTPUT_DIR="${2:-public/models}"

mkdir -p "$OUTPUT_DIR"

total_before=0
total_after=0

for file in "$INPUT_DIR"/*.glb "$INPUT_DIR"/*.gltf; do
  [ -f "$file" ] || continue

  filename=$(basename "$file" | sed 's/\.[^.]*$/.glb/')
  echo ""
  echo "Processing: $filename"

  # Step 1: Dedup and prune
  npx gltf-transform dedup "$file" "/tmp/step1-$filename" 2>/dev/null
  npx gltf-transform prune "/tmp/step1-$filename" "/tmp/step2-$filename" 2>/dev/null

  # Step 2: Resize textures to max 1024px
  npx gltf-transform resize "/tmp/step2-$filename" "/tmp/step3-$filename" \
    --width 1024 --height 1024 2>/dev/null

  # Step 3: Draco geometry compression
  npx gltf-transform draco "/tmp/step3-$filename" "$OUTPUT_DIR/$filename" 2>/dev/null

  before=$(wc -c < "$file" | tr -d ' ')
  after=$(wc -c < "$OUTPUT_DIR/$filename" | tr -d ' ')
  ratio=$((after * 100 / before))
  total_before=$((total_before + before))
  total_after=$((total_after + after))

  echo "  $before -> $after bytes (${ratio}% of original)"

  # Clean temp files
  rm -f /tmp/step*-"$filename"
done

echo ""
echo "=== Total: $total_before -> $total_after bytes ==="
if [ "$total_before" -gt 0 ]; then
  total_ratio=$((total_after * 100 / total_before))
  echo "=== Overall compression: ${total_ratio}% of original ==="
fi
```

### Step 3: Loading Screen with useProgress

```tsx
// src/components/LoadingScreen.tsx
import { useProgress, Html } from '@react-three/drei'

export function LoadingScreen() {
  const { progress, active, errors, item, loaded, total } = useProgress()

  if (!active) return null

  return (
    <Html center>
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#e0e0e0',
        fontFamily: 'system-ui, sans-serif',
      }}>
        {/* Game title */}
        <h1 style={{
          fontSize: '2.5rem',
          fontWeight: 700,
          marginBottom: '2rem',
          letterSpacing: '0.1em',
        }}>
          MY GAME
        </h1>

        {/* Progress bar */}
        <div style={{
          width: '300px',
          height: '4px',
          backgroundColor: '#333',
          borderRadius: '2px',
          overflow: 'hidden',
        }}>
          <div style={{
            width: `${progress}%`,
            height: '100%',
            backgroundColor: '#4a9eff',
            borderRadius: '2px',
            transition: 'width 0.3s ease',
          }} />
        </div>

        {/* Progress text */}
        <p style={{
          marginTop: '1rem',
          fontSize: '0.9rem',
          opacity: 0.6,
        }}>
          {progress.toFixed(0)}% — Loading {loaded}/{total}
        </p>

        {/* Current item (helpful for debugging slow loads) */}
        {import.meta.env.DEV && item && (
          <p style={{
            fontSize: '0.75rem',
            opacity: 0.4,
            marginTop: '0.5rem',
            maxWidth: '300px',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
          }}>
            {item}
          </p>
        )}

        {/* Error display */}
        {errors.length > 0 && (
          <p style={{ color: '#ff4444', marginTop: '1rem', fontSize: '0.85rem' }}>
            Failed to load {errors.length} asset(s)
          </p>
        )}
      </div>
    </Html>
  )
}
```

### Step 4: Error Boundary Wrapping the Canvas

```tsx
// src/components/ErrorBoundary.tsx
import { Component, type ReactNode } from 'react'

interface Props {
  children: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export class GameErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('[GameErrorBoundary]', error, info)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          height: '100vh',
          backgroundColor: '#0a0a1a',
          color: '#e0e0e0',
          fontFamily: 'system-ui, sans-serif',
          padding: '2rem',
          textAlign: 'center',
        }}>
          <h1 style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>
            Oops — the engine crashed
          </h1>
          <p style={{ opacity: 0.6, maxWidth: '400px', lineHeight: 1.6 }}>
            Your browser might not support WebGL2, or the GPU ran out of memory.
            Try reloading, or switch to a different browser.
          </p>
          <button
            onClick={() => window.location.reload()}
            style={{
              marginTop: '2rem',
              padding: '0.75rem 2rem',
              fontSize: '1rem',
              backgroundColor: '#4a9eff',
              color: 'white',
              border: 'none',
              borderRadius: '8px',
              cursor: 'pointer',
            }}
          >
            Reload
          </button>
        </div>
      )
    }
    return this.props.children
  }
}
```

### Step 5: Full App Composition

```tsx
// src/App.tsx
import { Suspense, lazy, useState } from 'react'
import { Canvas } from '@react-three/fiber'
import { GameErrorBoundary } from './components/ErrorBoundary'
import { LoadingScreen } from './components/LoadingScreen'

// Lazy-load the heavy game scene
const GameScene = lazy(() => import('./scenes/GameScene'))

export default function App() {
  const [started, setStarted] = useState(false)

  if (!started) {
    return (
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        height: '100vh',
        backgroundColor: '#0a0a1a',
        color: '#e0e0e0',
        fontFamily: 'system-ui, sans-serif',
      }}>
        <h1 style={{ fontSize: '3rem', marginBottom: '2rem' }}>MY GAME</h1>
        <button
          onClick={() => setStarted(true)}
          style={{
            padding: '1rem 3rem',
            fontSize: '1.2rem',
            backgroundColor: '#4a9eff',
            color: 'white',
            border: 'none',
            borderRadius: '12px',
            cursor: 'pointer',
            transition: 'transform 0.2s',
          }}
          onMouseOver={(e) => (e.currentTarget.style.transform = 'scale(1.05)')}
          onMouseOut={(e) => (e.currentTarget.style.transform = 'scale(1)')}
        >
          Play
        </button>
      </div>
    )
  }

  return (
    <GameErrorBoundary>
      <Canvas
        camera={{ position: [0, 5, 10], fov: 55 }}
        dpr={[1, 2]}
        gl={{ antialias: true, powerPreference: 'high-performance' }}
      >
        <Suspense fallback={<LoadingScreen />}>
          <GameScene />
        </Suspense>
      </Canvas>
    </GameErrorBoundary>
  )
}
```

### Step 6: Deploy to Vercel

```bash
# Option A: Vercel CLI
npm install -g vercel
vercel --prod

# Option B: Connect GitHub repo via vercel.com dashboard
# Push to GitHub, import in Vercel, auto-deploys on every push
```

```json
// vercel.json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    },
    {
      "source": "/models/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    }
  ]
}
```

### Step 7: Alternative — Package for itch.io

```bash
#!/bin/bash
# scripts/package-itch.sh
set -e

echo "Building for itch.io..."
npm run build

echo "Packaging..."
cd dist
zip -r ../game-itch.zip . -x "*.map"
cd ..

echo ""
echo "Done! Upload game-itch.zip to itch.io"
echo "File size: $(du -sh game-itch.zip | cut -f1)"
echo ""
echo "itch.io settings:"
echo "  - Kind of project: HTML"
echo "  - Check 'This file will be played in the browser'"
echo "  - Viewport: 960x640 (or your preferred resolution)"
echo "  - Enable fullscreen button"
```

---

## Common Pitfalls

### 1. Shipping Uncompressed Assets

This is the biggest file-size mistake. A raw Blender export can easily be 10–50MB. With Draco compression and texture optimization, the same model is often under 1MB.

```bash
# WRONG — shipping the raw export from Blender
cp model.glb public/models/
# Result: 12MB model, 8-second load on 4G

# RIGHT — compress before shipping
npx gltf-transform draco model.glb public/models/model.glb
# Result: 480KB model, sub-second load
```

### 2. Three.js in the Main Bundle

Without manual chunks, Vite puts Three.js in your main bundle. Every code change forces users to re-download ~600KB of Three.js that hasn't changed.

```typescript
// WRONG — no manual chunks, Three.js in main bundle
export default defineConfig({
  plugins: [react()],
  // Three.js bundled into index-xxxxx.js (800KB+)
})

// RIGHT — split Three.js into its own cacheable chunk
export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          three: ['three'],
          'react-vendor': ['react', 'react-dom'],
        },
      },
    },
  },
})
```

### 3. No Loading Screen

Without a loading screen, users see a blank page (or black canvas) for several seconds while assets download. They'll assume the page is broken and leave.

```tsx
// WRONG — no loading feedback
<Canvas>
  <GameScene /> {/* Takes 4 seconds to load models */}
</Canvas>

// RIGHT — Suspense with a loading screen
<Canvas>
  <Suspense fallback={<LoadingScreen />}>
    <GameScene />
  </Suspense>
</Canvas>
```

### 4. No Error Boundary

WebGL can fail. GPU drivers crash. Mobile browsers run out of memory. Without an error boundary, your users see a white screen with no explanation and no way to recover.

```tsx
// WRONG — crash = white screen of death
function App() {
  return (
    <Canvas>
      <GameScene />
    </Canvas>
  )
}

// RIGHT — graceful failure with recovery option
function App() {
  return (
    <GameErrorBoundary>
      <Canvas>
        <GameScene />
      </Canvas>
    </GameErrorBoundary>
  )
}
```

### 5. Missing Cache Headers

Without proper cache headers, browsers re-download all your assets on every visit. Your hashed JS files, your compressed models, your textures — all re-fetched every time.

```json
// WRONG — no cache headers, everything re-downloads
// (default behavior on most hosting platforms)

// RIGHT — immutable caching for hashed assets
// vercel.json
{
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    }
  ]
}
```

---

## Exercises

### Exercise 1: Bundle Analysis

**Time:** 20–30 minutes

Install `vite-bundle-visualizer` and analyze your project's production build:

```bash
npm install -D vite-bundle-visualizer
npx vite-bundle-visualizer
```

Answer these questions:
- What is your total bundle size (gzipped)?
- What is the single largest module?
- Is Three.js in a separate chunk?
- Are there any unexpected large dependencies?

If Three.js isn't split, add `manualChunks` to your Vite config and re-run the analysis. Compare before and after.

**Stretch goal:** Get your total JS bundle under 500KB gzipped.

### Exercise 2: Draco Compression

**Time:** 20–30 minutes

Take any GLTF/GLB model from your projects (or download one from [Sketchfab](https://sketchfab.com)) and compress it:

```bash
# Check original size
ls -lh model.glb

# Compress with Draco
npx gltf-transform draco model.glb model-compressed.glb

# Check compressed size
ls -lh model-compressed.glb
```

Load both versions in your R3F scene and verify the compressed version looks identical. Measure the size difference. Try the full pipeline (dedup, prune, resize, draco) and see how much further you can push it.

**Stretch goal:** Write a script that compresses all models in a directory and outputs a report with before/after sizes.

### Exercise 3: PWA Setup

**Time:** 30–45 minutes

Add PWA support to your project:

1. Install `vite-plugin-pwa` and configure it in `vite.config.ts`
2. Create icons (192x192 and 512x512 PNG) — even a simple colored square works
3. Build and preview the project
4. Verify in Chrome DevTools > Application that the manifest and service worker are registered
5. Test the "Install" button in Chrome's address bar
6. Disconnect your network and verify the game still loads from cache

**Stretch goal:** Customize the offline fallback page with a "You're offline, but the game still works!" message.

### Exercise 4: Ship It

**Time:** 30–60 minutes

Take your best project from any module in this roadmap and ship it. This is the final exercise, and it's the most important one.

1. Add an error boundary around the Canvas
2. Add a loading screen with `useProgress`
3. Compress any 3D assets with Draco
4. Add manual chunks to your Vite config
5. Build and test locally with `npm run preview`
6. Deploy to Vercel (`vercel --prod`) or package for itch.io
7. Open the live URL on your phone and on a different computer
8. Share the link

You just shipped a game. That puts you ahead of the vast majority of aspiring game developers who never get past "working on it."

---

## Recommended Reading

| Resource | Type | Why |
|----------|------|-----|
| [Vite Build Documentation](https://vitejs.dev/guide/build.html) | Official Docs | Deep dive into build configuration, chunking, and optimization |
| [gltf-transform Documentation](https://gltf-transform.dev/) | Official Docs | Complete reference for the asset compression pipeline |
| [web.dev Performance](https://web.dev/performance/) | Guide | Google's guide to web performance — Lighthouse metrics explained |
| [Vercel Documentation](https://vercel.com/docs) | Official Docs | Deployment, caching, edge functions, environment variables |
| [itch.io Creator Guide](https://itch.io/docs/creators/) | Official Docs | Everything about publishing on itch.io |
| [vite-plugin-pwa](https://vite-pwa-org.netlify.app/) | Official Docs | PWA setup guide for Vite projects |
| [@react-three/xr](https://github.com/pmndrs/xr) | GitHub | WebXR integration for R3F — VR and AR in the browser |
| [Poimandres Discord](https://discord.gg/poimandres) | Community | The community behind R3F, drei, and the entire ecosystem |

---

## Key Takeaways

1. **Ship first, polish later.** A live URL with a rough game beats a local machine with a perfect one. The shipping muscle gets stronger every time you use it. Make "deploy" a habit, not an event.

2. **Compress everything.** Draco for geometry (90%+ reduction), KTX2 for textures, manual chunks for code splitting. The difference between a 50MB load and a 2MB load is the difference between players staying and players leaving.

3. **Loading screens and error boundaries are not optional.** Users will see a blank page while assets load and a white screen when WebGL crashes. Both are solved with a few lines of code. Do it for every project, every time.

4. **Cache headers are free performance.** Hashed assets with `immutable` cache headers mean returning users load your game almost instantly. This costs nothing to implement and dramatically improves the experience.

5. **PWAs make web games feel native.** A manifest, a service worker, and some icons turn your web game into an installable app that works offline. The effort-to-impact ratio is excellent.

6. **The ecosystem keeps growing.** WebXR, native desktop with Tauri, mobile with React Native, AI integration — the R3F foundation you've built opens doors in every direction. Pick the path that excites you most.

---

## What's Next?

There is no Module 14. This is where the roadmap ends and your own path begins.

You've gone from zero to shipping a 3D game in the browser. You understand the renderer, the physics, the shaders, the state management, the audio, the UI, the ECS patterns, and now the deployment pipeline. That's a complete skill set. Not a theoretical one — a practical one, backed by projects you've actually built.

Here's what I'd suggest: go build something. Not another tutorial project. Something that's yours — an idea that's been rattling around in your head, a game jam entry, a weird experiment that might not even work. The best way to solidify everything you've learned is to use it on a problem nobody has solved for you.

And when you ship it — and you will ship it, because now you know how — come back and share it with the community. Post it in the Poimandres Discord. Put it on itch.io. Tweet the URL. The web is the most accessible game platform ever created, and you now have the tools to put your work on it.

Go make something. Ship it. Then make something better.

[Back to R3F Game Dev Learning Roadmap](r3f-gamedev-learning-roadmap.md)