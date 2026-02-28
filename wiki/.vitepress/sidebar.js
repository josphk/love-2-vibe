import fs from 'node:fs'
import path from 'node:path'

const wikiRoot = path.resolve(import.meta.dirname, '..')

function extractH1(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8')
  const match = content.match(/^#\s+(.+)$/m)
  if (!match) return null
  // Strip markdown image/badge syntax from title
  return match[1].replace(/\s*\[!\[.*?\]\(.*?\)\]\(.*?\)/g, '').trim()
}

function buildTopicSidebar(dir) {
  const dirPath = path.join(wikiRoot, dir)
  const files = fs.readdirSync(dirPath).filter(f => f.endsWith('.md'))

  // Find the roadmap file (contains "roadmap" in name)
  const roadmapFile = files.find(f => f.includes('roadmap'))
  // Find module files
  const moduleFiles = files.filter(f => f.startsWith('module-')).sort()
  // Everything else (gauntlets, guides, etc.) — exclude roadmap and modules
  const extraFiles = files
    .filter(f => f !== roadmapFile && !f.startsWith('module-'))
    .sort()

  const items = []

  // Roadmap first
  if (roadmapFile) {
    const label = extractH1(path.join(dirPath, roadmapFile)) || 'Roadmap'
    items.push({ text: label, link: `/${dir}/${roadmapFile}` })
  }

  // Modules in order
  for (const file of moduleFiles) {
    const label = extractH1(path.join(dirPath, file)) || file.replace('.md', '')
    items.push({ text: label, link: `/${dir}/${file}` })
  }

  // Extra files at the end
  for (const file of extraFiles) {
    const label = extractH1(path.join(dirPath, file)) || file.replace('.md', '')
    items.push({ text: label, link: `/${dir}/${file}` })
  }

  return items
}

function buildAwesomeSidebar(dir) {
  const dirPath = path.join(wikiRoot, dir)
  const files = fs.readdirSync(dirPath).filter(f => f.endsWith('.md'))
  const items = []

  // README first
  if (files.includes('README.md')) {
    const label = extractH1(path.join(dirPath, 'README.md')) || dir
    items.push({ text: label, link: `/${dir}/README.md` })
  }

  // Other md files
  for (const file of files.filter(f => f !== 'README.md').sort()) {
    const label = extractH1(path.join(dirPath, file)) || file.replace('.md', '')
    items.push({ text: label, link: `/${dir}/${file}` })
  }

  return items
}

// Topic display names for sidebar group headers
const topics = {
  'love2d': 'LOVE2D',
  'godot': 'Godot 4',
  'r3f': 'React Three Fiber',
  'ecs': 'ECS',
  'glsl': 'GLSL Shaders',
  'game-ai': 'Game AI',
  'rive': 'Rive',
  'sound-design': 'Sound Design',
  'game-design-theory': 'Game Design Theory',
  'indie-marketing': 'Indie Marketing',
  'monetization': 'Monetization',
  'awesome-love2d': 'Awesome LOVE2D',
  'awesome-gamedev': 'Awesome Gamedev',
}

export function generateSidebar() {
  const sidebar = {}

  for (const [dir, label] of Object.entries(topics)) {
    const isAwesome = dir.startsWith('awesome-')
    const items = isAwesome ? buildAwesomeSidebar(dir) : buildTopicSidebar(dir)

    sidebar[`/${dir}/`] = [{ text: label, items }]
  }

  return sidebar
}
