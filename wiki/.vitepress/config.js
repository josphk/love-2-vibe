import { defineConfig } from 'vitepress'
import { generateSidebar } from './sidebar.js'

export default defineConfig({
  title: 'Game Dev Wiki',
  description: 'A curated learning resource for game development',

  // Allow links to not-yet-written modules (sound-design has a roadmap but no module files yet)
  ignoreDeadLinks: [
    /\.\/module-\d+-/,
  ],

  markdown: {
    config: (md) => {
      // Add v-pre to inline code so Vue doesn't treat {{ }} as template expressions
      md.renderer.rules.code_inline = (tokens, idx) => {
        const content = md.utils.escapeHtml(tokens[idx].content)
        return `<code v-pre>${content}</code>`
      }
    },
  },

  themeConfig: {
    search: { provider: 'local' },

    nav: [
      {
        text: 'Engines',
        items: [
          { text: 'LOVE2D', link: '/engines/love2d/love2d-learning-roadmap' },
          { text: 'Godot 4', link: '/engines/godot/godot4-gamedev-learning-roadmap' },
          { text: 'React Three Fiber', link: '/engines/r3f/r3f-gamedev-learning-roadmap' },
        ],
      },
      {
        text: 'Programming',
        items: [
          { text: 'ECS', link: '/programming/ecs/ecs-learning-roadmap' },
          { text: 'GLSL Shaders', link: '/programming/glsl/glsl-learning-roadmap' },
          { text: 'Gameplay Ability System', link: '/programming/gas/gas-learning-roadmap' },
        ],
      },
      {
        text: 'Design',
        items: [
          { text: 'Game Design Theory', link: '/design/game-design-theory/game-design-theory-roadmap' },
          { text: 'Game Balance', link: '/design/game-balance/game-balance-roadmap' },
          { text: 'Game AI', link: '/design/game-ai/game-ai-learning-roadmap' },
        ],
      },
      {
        text: 'Art & Audio',
        items: [
          { text: 'Rive', link: '/art-audio/rive/rive-learning-roadmap' },
          { text: 'Sound Design', link: '/art-audio/sound-design/sound-design-learning-roadmap' },
        ],
      },
      {
        text: 'Business',
        items: [
          { text: 'Indie Marketing', link: '/business/indie-marketing/indie-marketing-learning-roadmap' },
          { text: 'Monetization', link: '/business/monetization/game-monetization-learning-roadmap' },
        ],
      },
      {
        text: 'Resources',
        items: [
          { text: 'Awesome LOVE2D', link: '/resources/awesome-love2d/README' },
          { text: 'Awesome Gamedev', link: '/resources/awesome-gamedev/README' },
        ],
      },
    ],

    sidebar: generateSidebar(),
  },
})
