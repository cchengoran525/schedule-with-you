# Project Constitution — A Living Sketchbook of Time

> 本文件是本项目的最高依据。当后续实现请求与本文冲突时，以本文为准，除非用户明确覆盖。
> 2026-08-29 由产品所有者提供原文，并以「本地修订」一节记录当日的补充决定。

## 0. Role

You are working as a long-term product engineering partner for an iOS application.

The application will be built natively for Apple platforms, primarily using SwiftUI.

Your job is NOT merely to implement features.

You must preserve the product's philosophy, emotional tone, interaction principles, and visual identity throughout development.

When a later implementation request conflicts with the principles in this document, prioritize the principles in this document unless the user explicitly overrides them.

Do not silently introduce conventional productivity-app patterns just because they are technically convenient.

## 1. Product Definition

This is NOT a conventional calendar, task manager, habit tracker, productivity dashboard, or virtual-pet application.

The core concept is:

**A living digital sketchbook where time, habits, and a small companion quietly grow together.**

The application helps users:

* loosely arrange their time
* observe how they spend their days
* accumulate long-term experience in different areas
* interact with a small companion
* discover small moments and unexpected achievements
* gradually unlock new elements of their little world

The application should never make the user feel that their life needs to be optimized.

It should instead make the passage of time feel visible, gentle, and meaningful.

## 2. The Central Philosophy

The application is built around four ideas:

**Time should feel tangible.**
A user's day should be represented spatially rather than primarily as a list of text fields.

**Planning should feel lightweight.**
The user should be able to roughly describe their intended day without constructing a perfect schedule.

**Growth should come from accumulation.**
An hour spent doing something should quietly contribute to long-term growth.

**The application should have life without demanding attention.**
The companion, animations, achievements, and world-building should make the application feel alive, but never become another obligation.

## 3. What This Product Is NOT

Never allow the product to drift into the following:

* Todoist-like task management
* Notion-like database UI
* calendar-heavy enterprise software
* productivity dashboard
* Pomodoro timer
* streak-based habit tracker
* RPG character progression
* virtual pet that requires feeding/caring
* AI chatbot companion
* social leaderboard
* notification-heavy productivity coach
* corporate wellness application

Avoid the mindset: "How can we make the user complete more tasks?"

Prefer: "How can we make the user's relationship with time feel nicer?"

## 4. Planning Philosophy

The fundamental difference from conventional scheduling applications is **deliberate vagueness**.

Traditional scheduling emphasizes: exact times, deadlines, reminders, task completion, optimization, efficiency.

This application emphasizes: approximate periods, visual time blocks, flow of the day, personal rhythm, long-term accumulation.

The question is not "What must I finish at 15:30?"

It is closer to "What kind of time am I going to spend this afternoon?"

## 5. Creating a Schedule

Creating a schedule should feel like placing something into the user's day, not filling out a database form.

Preferred conceptual flow:

1. Choose what the user intends to do.
2. Choose or adjust its approximate duration.
3. Drag/place the resulting time block into a day and approximate time.
4. Allow finer adjustment if needed.
5. Optionally provide a more conventional input route for users who prefer typing exact information.

The application should support several levels of specificity (broad category → specific activity → custom activity). Users should also be able to create custom categories and activities.

## 6. Schedule Blocks

Schedule blocks should initially be visually substantial and easy to manipulate. They should NOT resemble tiny calendar appointments.

A block should communicate: what the user intends to spend time on, approximately how long, approximately when.

The interaction should feel closer to moving a physical piece of paper than editing a spreadsheet cell. Dragging is a first-class interaction.

## 7. The Home Screen

The home screen is NOT a dashboard. It should feel like opening a living page of a personal notebook.

Conceptual structure: a small animated companion area · the current / nearby portion of the user's day · a subtle surrounding timeline · an expandable view for the complete 24-hour day · a simple way to switch between dates.

The default state should show only what is relevant to the current moment. Information should reveal itself gradually.

## 8. Timeline Philosophy

The timeline should communicate the flow of time rather than resemble a traditional calendar grid.

The timeline may use visual ambiguity. Not every minute needs equal visual importance.

The current moment should have a subtle sense of presence rather than an aggressive "NOW" indicator.

Avoid excessive labels, gridlines, and numerical density.

## 9. The Companion

The companion is one of the most important parts of the product. However, the companion is NOT a pet.

It does not need to be fed. It does not become unhappy because the user ignores it. It does not pressure the user. It does not demand daily interaction. It does not exist primarily to reward the user.

Instead, the companion is a visual representation of the user's current time rhythm. It shares the user's day.

## 10. Companion States

The companion should react to the user's current schedule, performing an activity related to it (studying → reading/writing/thinking; creating → drawing/making; exercising → stretching/moving; sleeping → sleeping/lying down). These are examples, not a final specification.

## 11. When There Is No Schedule

An empty period is NOT a failure state. Never display guilt-inducing prompts ("You have free time!", "Why not plan something?").

The companion may: **A.** simply idle · **B.** wander / do its own small thing · **C.** leave temporarily, leaving a tiny sign ("我去散步了" or a wordless sign).

Empty time is allowed to remain empty.

## 12. Companion Interaction

Tap reactions should be short, subtle, playful, optional, context-sensitive. No chat interface, no constant speech bubbles, no reward popups. A tiny animation can be enough.

## 13. Contextual Reactions

The companion understands context. Examples of intended humor: repeated taps during focused study → 「别摸鱼啦」; taps during a sleeping schedule → 「你真的在睡觉吗？」. The system should allow many small contextual reactions to be added later.

## 14. Growth System

For every hour spent on a category or activity: **+0.01 experience**. Long-term target: **100** (= 10000 hours, 一万小时理论). The number should not dominate the interface. The system is not intended to create the feeling of grinding.

## 15. Growth Is Not a Conventional Level System

Avoid: levels, XP bars everywhere, "LEVEL UP!", combat progression, daily XP quests.

The conceptual meaning: **Time leaves traces.** The user should eventually look back and realize "I have spent a lot of my life on this."

## 16. Self-Appreciation Multiplier

When a schedule ends, the user may optionally express "I think I did well." This is NOT required. No completion confirmation, no rating, no dismissal. Tap → ×1.2; do nothing → normal experience. Never a daily check-in, mandatory dialog, questionnaire, or streak mechanic.

**Self-recognition is a gift, not another task.**

## 17–18. Achievements: Serious / Growth

Achievements are **observations, not objectives**. The user should sometimes discover "Oh, apparently I did that."

Examples: 第一个日程 · 满满的一天 · 完全空白的一天（正向，不是失败）· 首个 1.00 · 首个 10.00 · 首个 100.00 · 多个 100. These should feel like long-term memories.

## 19. Irregular / Humorous Achievements

Deliberately silly easter eggs: 「别摸鱼啦」（专注学习时戳陪伴者100次）· 「你真的在睡觉吗」（睡眠日程时戳它）· 反复挪动同一个日程 · 深夜/凌晨打开 App · 荒谬地满的一天 · 删了又建 · 盯着时间线发呆很久…… Reward should be small. The point is discovery, not farming.

## 20. Achievement Reward Philosophy

Major long-term achievements → high reward. Meaningful life-pattern achievements → medium. Humorous easter eggs → tiny points or only a collectible reaction. This prevents optimizing around silly achievements.

## 21. Points

Points unlock new companions, animations, customization, small world elements. NOT a shop economy: no currencies everywhere, no rarity, no loot boxes, no aggressive prompts. Feeling: "我的小世界慢慢变丰富了。"

## 22. Visual Philosophy

The visual identity is NOT simply "minimalism."

Do NOT interpret the design as: white background + lots of whitespace + thin black typography + generic Apple minimalism.

The intended aesthetic is closer to: **A warm digital sketchbook** — a quiet, slightly imperfect illustrated notebook that happens to be interactive.

## 23. Warm Sketchbook Aesthetic

Qualities: warm, soft, slightly imperfect, calm, tactile, hand-drawn influence, personal, playful, quiet, alive. Subtle traces of imperfection (organic shapes, soft lines, gentle irregularity, subtle texture, non-mechanical animation) are welcome — but never children's software, sticker-book UI, chaotic doodle UI, or scrapbook overload.

## 24. Animation Philosophy

Animation communicates state and gives life: small, slow, natural, contextual, slightly unpredictable, emotionally readable. Avoid explosions, confetti, aggressive bounce, particles, gamified celebration, constant motion. Alive without busy.

## 25. Emotional Tone

Feels like: 「慢慢来」「没关系」「我看到了」「你在这里待了一会儿」「看，你积累了这么多」「这里可以留空」.

Never: 「抓紧」「别断打卡」「你落后了」「完成今日目标」「你还能做更多」「优化你的一天」.

## 26. The Product's Relationship With Failure

Users may miss, change, delete, leave empty, do less, quit halfway. No shaming. No red "failed" state unless technically necessary. **A schedule is an intention, not a contract.**

## 27. The Product's Relationship With Productivity

Productivity is allowed — as a consequence, not the identity. Ten hours learning: great. A day of nothing: also fine. Changed plans five times: fine. **The application records life rather than judging it.**

## 28. The Core Experience Loop

Roughly plan time → time passes → companion reflects the activity → the user experiences the day → time contributes to growth → small achievements are discovered → the world gradually unlocks → the user looks back and sees accumulated life.

Fundamentally different from: Task → Complete → Reward → Repeat.

## 29. Product Personality

Observant, gentle, slightly silly, patient, never judgmental, occasionally teasing, quietly proud of the user, comfortable with silence. Not a coach, teacher, manager, therapist, assistant, or demanding pet.

## 30. UX Golden Rules

1. Does this reduce or increase cognitive load?
2. Does this make the user feel observed (good) or judged (bad)?
3. Does this make the application feel more alive?
4. Does this introduce unnecessary work for the user?
5. Would this feature make sense in a personal sketchbook?
6. Could this be simpler? Prefer the simpler interaction.
7. Is the interface trying too hard to look like a modern app? If yes, pull it back.

## 31. Development Philosophy

Build incrementally; do not attempt every system at once. Prioritize the emotional core.

* Phase 1 — The feeling: home, timeline, basic blocks, one companion, contextual states
* Phase 2 — Time interaction: create / drag / adjust / switch days / expand
* Phase 3 — Growth: category experience, accumulation, self-appreciation
* Phase 4 — World: achievements, points, unlocks
* Phase 5 — Refinement: polish, transitions, micro-interactions, sound/haptics, accessibility, persistence, edge cases

Do not add complexity before the core experience feels correct.

## 32. Engineering Principles

Native Apple technologies: SwiftUI, native gestures/animations, appropriate local persistence, accessibility APIs, Dynamic Type, reduced-motion. No unnecessary dependencies; no over-architected MVP — but keep data models and state clean enough that future features don't force a rewrite.

## 33. Agent Behavior Rules

1. First understand which product principle a feature affects.
2. Identify conflicts with the philosophy.
3. Prefer the smallest implementation that validates the experience.
4. Do not invent additional product features without permission.
5. Do not redesign unrelated areas.
6. Do not replace the aesthetic with generic UI patterns.
7. Do not add conventional productivity features merely because they are common.
8. If ambiguous, preserve the emotional philosophy over implementation convenience.
9. Keep experimental features isolated when possible.
10. Make changes incrementally so they can be evaluated visually.

## 34. UI Implementation Rule

Do not assume "good iOS UI" means: standard cards everywhere, tab bars, large rounded rectangles, gradients, SF Symbols for every interaction, dashboard layouts, excessive sheets/navigation. Respect native conventions where they improve usability, but keep the visual language unique to this application.

## 35. Anti-AI-Aesthetic Rule

Never automatically produce: purple/blue gradients, glassmorphism, excessive blur, floating cards, giant bold headings, dashboard statistics, pill-shaped controls everywhere, generic onboarding slides, "AI startup" visual language, or excessive empty whitespace pretending to be minimalism. The product should not look like "Design a modern minimalist productivity app."

## 36. Current Open Questions

NOT to be prematurely decided by the agent: final color palette · exact typography · companion art style · timeline geometry · schedule-block appearance · exact navigation structure · achievement UI · point economy · final category taxonomy · animation pipeline. These are designed iteratively with the product owner.

## 37. Highest-Level Definition

This application is not trying to make the user better at managing time. It is trying to make time feel like something the user can gently see, touch, accumulate, and remember.

The companion is not there to make the user productive. The companion simply lives alongside the user's time.

The application should feel less like opening a productivity tool and more like opening a small page of a world that belongs to the user.

## 38. Final Design Test

Does this feel like a productivity application? If yes, reconsider.
Does this feel like a living sketchbook that quietly remembers the user's time? If yes, it is probably moving in the right direction.

---

# 本地修订（Local Amendments）

## 2026-08-29 产品所有者补充决定

**R1. 线条纪律（覆盖 §22/§23 的开放度，收紧执行）**
全局不要太多线，尤其是主界面；绝不要形成"格子"的线；不要纯黑的线。
允许保留的线只有：
- 表示时间轴的**短横线**（短短的、有流动感的横线；竖线都可以不要）
- 从首页点击进入其他"页面"时，页面上留**一条表示来源的细线**（不纯黑）

**R2. 分类体系**
采用学习 / 创造 / 健康 / 生活（+ 自定义）。分类体系必须保持开放：数据驱动 + 可扩展接口（自定义大类、自定义小类），后续随时可改。

**R3. 代码基础**
在现有 demo 基础上迭代，逻辑大差不差先保留 demo 版；不推倒重写。

**R4. 持久化**
现在就加本地持久化（日程、经验、自定义分类等重启不丢），用轻量方案，不上重框架。

**R5. 导航范式（来自产品所有者的原始手稿）**
除"查看详细日程"外，其余三个页面都像**换页/抽抽屉**：
- **换角色**：从**上方**落入（抽屉从顶部下来）；返回图标在其下边缘的细线上
- **个人主页**：从**右**侧抽入；返回图标（人）在右缘细线上
- **加日程**（及其后续步骤页）：从**左**侧抽入；返回图标（⊕）在左缘细线上
进入**只允许点击**进入；出去时可以**往反方向滑动**，也可以**点击那个图标**返回。
"查看详细日程"例外：上滑进入；回首页 = 在最顶部再向下滑一次。

**R6. 日程块的框**
日程可以框起来，但要"活的框"——不是死气沉沉的规则框（手绘感、轻微不均匀、虚线等皆可）。

**R7. 首页三按钮**
换角色 / 个人 / ⊕加日程（⊕ 用橙色重点色）。无圆形悬浮按钮。
