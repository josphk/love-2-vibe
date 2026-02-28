import { defineConfig } from 'vitepress'
import { generateSidebar } from './sidebar.js'

export default defineConfig({
  title: 'Game Dev Wiki',
  description: 'A curated learning resource for game development',

  ignoreDeadLinks: true,

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
          { text: 'LOVE2D', link: '/love2d/love2d-learning-roadmap' },
          { text: 'Godot 4', link: '/godot/godot4-gamedev-learning-roadmap' },
          { text: 'React Three Fiber', link: '/r3f/r3f-gamedev-learning-roadmap' },
        ],
      },
      {
        text: 'Programming',
        items: [
          { text: 'ECS', link: '/ecs/ecs-learning-roadmap' },
          { text: 'GLSL Shaders', link: '/glsl/glsl-learning-roadmap' },
          { text: 'Game AI', link: '/game-ai/game-ai-learning-roadmap' },
        ],
      },
      {
        text: 'Art & Audio',
        items: [
          { text: 'Rive', link: '/rive/rive-learning-roadmap' },
          { text: 'Sound Design', link: '/sound-design/sound-design-learning-roadmap' },
        ],
      },
      {
        text: 'Design & Business',
        items: [
          { text: 'Game Design Theory', link: '/game-design-theory/game-design-theory-roadmap' },
          { text: 'Indie Marketing', link: '/indie-marketing/indie-marketing-learning-roadmap' },
          { text: 'Monetization', link: '/monetization/game-monetization-learning-roadmap' },
        ],
      },
      {
        text: 'Resources',
        items: [
          { text: 'Awesome LOVE2D', link: '/awesome-love2d/README' },
          { text: 'Awesome Gamedev', link: '/awesome-gamedev/README' },
        ],
      },
    ],

    sidebar: generateSidebar(),
  },
})
