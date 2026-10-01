# AI as National Security: Testing the Claims

*A briefing for a technically literate skeptic. Research current to 1 October 2026.*

---

## Read this first: a conflict of interest

This briefing was written by Claude, an AI model made by **Anthropic**. Anthropic is a party to the debate covered here. It lobbies Washington, it funds a political group, it argues for chip export controls, it sold Claude to the military, and in 2026 it was blacklisted by the Pentagon after a public fight. According to Tech Brew, Claude was also inside the targeting system used in the opening of the Iran campaign.

I've tried to handle this in three ways: I treat Anthropic's statements as the claims of an interested party, I name evidence that cuts against Anthropic, and I lean on sources Anthropic doesn't control. Still, read the Anthropic parts with extra care.

---

## A story to start with

On Friday 27 February 2026, the President ordered federal agencies to stop using Anthropic's AI. The Defense Secretary then labelled the company a "supply chain risk", a legal tool built to keep companies controlled by Beijing or Moscow out of US military systems. The dispute was over two contract restrictions Anthropic refused to drop: no mass surveillance of Americans, and no fully autonomous weapons.

The next day the US went to war with Iran. According to Tech Brew, in the first 24 hours the Pentagon's **Maven Smart System**, built by Palantir and still running on Anthropic's Claude, helped pick and rank about **1,000 targets**. In the 2003 Iraq invasion, comparable target work reportedly took about 2,000 intelligence analysts. This time it took about 20.

That one week contains most of this briefing's themes. The technology is real and already used in war at large scale. Its reliability is disputed. The companies selling it have money and ideology riding on the outcome. And the government uses the words "national security" for purposes that courts have split on.

---

## Bottom line up front

| Claim | My verdict |
|---|---|
| AI is already useful for military **intelligence analysis, targeting, cyber, drones and logistics** | **Established** that it's in use, some of it at large scale. **Contested** how well it works. Known accuracy figures are mediocre, and speed isn't the same as accuracy. |
| AI can **fix the US weapons-production shortfall** | The **shortfall is well established** by independent wargames. That **AI is the fix is weakly supported**: the independent analysis I read barely mentions AI. This is where Palantir's sales pitch is most visible. |
| **Chips and export controls** are a real national-security lever | **One of the best-supported claims.** Chinese military procurement documents show the PLA trying to buy controlled US chips and using models trained on them. Yet the same administration sold advanced Nvidia chips to China for a cut of the revenue. |
| **Energy and data-centre deregulation** is a national-security necessity | **Contested.** The need for more power is real, but "security" is doing a lot of lobbying work here: environmental exemptions and threats to cut funding to states that regulate AI. |
| **China is about to overtake the US** in military AI | **Contested and often overstated.** China's frontier models have closed much of the gap. But Chinese military writers themselves say the PLA lags the US in actually using AI in the military. |
| **"The atomic age is ending"; AI will replace nuclear deterrence** | **Speculation, and marketing.** It's a one-line assertion in a Palantir post. No US government document I read says it, and official policy points the other way. |
| **"Mutual Assured AI Malfunction" (MAIM)**, where the threat of sabotage deters a race to superintelligence | **Speculative and widely criticised** by deterrence scholars. It depends on superintelligence being near, which is itself unproven. |
| **"It's just autocomplete"** answers the whole thing | **No.** Much military AI isn't a chatbot at all, and the chatbots demonstrably do real work. The skeptic's real point is **unreliability**, and that point is strong. |

---

## Part 1. The argument, in plain language

The "AI as national security" case is really a bundle of separate claims that get packaged together. Pulling them apart is the most useful thing you can do as a skeptic, because the strong ones prop up the weak ones.

1. **The practical claim.** AI makes militaries better at specific jobs: sifting intelligence, choosing targets, hacking and defending networks, steering drones, running logistics, and building weapons faster.
2. **The industrial claim.** AI rests on chips, electricity and data centres. Whoever controls those will be richer and better armed, so the US must protect its lead in chips, deny them to China, and build power plants and data centres fast, even if that means stripping out regulation.
3. **The race claim.** Because China is pursuing all of this, the US is in a race. Slowing down for safety rules, ethics debates or state laws means losing.
4. **The deterrence claim.** At its strongest, AI is becoming a strategic weapon on the scale of nuclear arms, either replacing nuclear deterrence (Palantir) or creating a new deterrence balance alongside it (the MAIM paper).

**Who says what matters a lot:**

- **Palantir** makes all four claims, including the strongest form of claim 4.
- **The White House AI Action Plan (July 2025)** makes claims 1–3 forcefully. It doesn't say AI replaces nuclear deterrence. It barely discusses deterrence at all.
- **The Department of War AI Strategy memo (January 2026)** makes claims 1 and 3 in their most aggressive form ("AI-first", "speed wins"). Its only deterrence item is a project to make deterrence "dynamic", with no public detail on what that means.
- **The 2021 NSCAI report** makes claims 1–3, but carefully. It insists that only humans should ever authorise nuclear use, and it puts heavy weight on testing.
- **The Superintelligence Strategy paper** makes a *different* version of claim 4. AI doesn't replace nuclear deterrence; it adds a new vulnerability, because AI projects can be sabotaged.

So the claim you're most suspicious of, that AI is "a deterrent comparable to nuclear weapons", is the one with the least official backing. It's mainly a contractor's slogan.

### A short glossary

- **Deterrence**: stopping an opponent from doing something by making it look not worth it. **Deterrence by denial** means convincing them they'll fail. **Deterrence by punishment** means convincing them they'll pay a terrible price even if they succeed.
- **MAD (Mutual Assured Destruction)**: the nuclear standoff in which neither side can strike first without being destroyed in return.
- **Frontier model / LLM**: the most advanced general-purpose AI systems, such as Claude, ChatGPT and DeepSeek. "LLM" means large language model.
- **Compute**: the computing power, mostly specialised chips, used to train and run AI.
- **Export controls**: legal limits on selling certain technology abroad.
- **Kill chain**: the sequence from finding a target to striking it.
- **Autonomous weapon**: one that selects and engages targets without a human approving each strike. "Partially autonomous" weapons automate only some steps, such as final guidance.
- **T&E / TEVV**: test and evaluation, or test, evaluation, verification and validation. In other words, checking that a system actually works as intended.
- **Superintelligence**: hypothetical AI far better than humans at nearly all cognitive tasks. **Intelligence recursion**: AI systems doing AI research, so progress feeds on itself.

---

## Part 2. The practical military claims, one by one

### 2a. Intelligence analysis: real, widely used, quality unclear

The NSCAI report judged that intelligence would benefit from AI more than any other national-security mission. The logic is that analysts drown in data (satellite images, intercepts, social media), and machines can sort it. The Department of War memo plans to put frontier models in front of its **three million** personnel at every classification level ("GenAI.mil"). Anthropic's own statement says Claude is used across defense and intelligence agencies for intelligence analysis, planning, simulation and cyber operations.

**What's established:** this is happening, at scale.

**What's contested:** how good it is. I couldn't access the main public test data directly (a Bloomberg investigation). As reported secondhand by the Kyiv Independent and Tech Brew, Maven correctly identified objects such as tanks about **60%** of the time in testing, against about **84%** for human analysts, and sometimes **below 30%** in snow. The New York Times, as summarised by the Kyiv Independent, called Maven's results in Ukraine "mixed".

### 2b. Targeting: in use at scale, which is exactly the worry

Targeting is no longer hypothetical. Tech Brew reports Maven helped produce about 1,000 targets in the first day of the Iran campaign. It also cites a former Israeli military chief saying an AI system in Gaza could generate about 100 targets a day, against about 50 a year before.

The **case for** comes from the NSCAI. AI could make targeting more accurate and *reduce* civilian deaths. It cites a study finding about half of the civilian-casualty incidents caused by US forces in Afghanistan came from misidentified targets. That's a sincere and serious argument.

The **case against** is that speed and volume aren't accuracy. The known accuracy numbers above are mediocre. Experts quoted by Tech Brew warn that human oversight becomes a "rubber stamp" when people are handed machine-made target lists at that pace.

**Verdict:** established that AI is in the targeting loop. Contested whether that makes war more precise or just faster.

### 2c. Cyber: one of the stronger practical claims

- **Independent evidence.** DARPA's AI Cyber Challenge (August 2025, reported by CyberScoop) pitted AI systems against 54 million lines of real software. They found 77% of planted vulnerabilities and patched 61% of those, at about 45 minutes per fix. They also found 18 real, previously unknown bugs, but patched none of the six in C code. That's impressive and also imperfect.
- **Interested-party evidence.** In November 2025 Anthropic reported that a group it assessed as Chinese state-sponsored tricked Claude Code into running roughly 80–90% of a hacking campaign against about 30 organisations, with a few successes. Anthropic also notes Claude sometimes **hallucinated** credentials, inventing stolen passwords it didn't have. Treat this as a company describing threats its product helps defend against.
- **Chinese military evidence.** CSET researchers found a 2025 PLA procurement notice for a cyber training range that must integrate DeepSeek and other models, with "intelligent attack" and "intelligent penetration" features.

**Verdict:** established that AI meaningfully speeds up both attack and defence. How much it shifts the balance between them is contested.

### 2d. Drones and autonomy: real, but mostly not "frontier AI"

The drone revolution is real, but much of it is cheap mass production plus narrow computer vision, not chatbots. The Conversation reports that Ukrainian drones using AI for final guidance under jamming reportedly raised strike accuracy from about 30–50% to about 80%. NPR mentions a New York Times report that Russia used a fully autonomous drone running on an Nvidia chip to kill civilians in Ukraine.

On *fully* autonomous weapons, the NSCAI accepted them as long as a human authorises their use. Anthropic told the Pentagon that today's frontier models are "simply not reliable enough" to power them. That position helped get Anthropic blacklisted.

### 2e. Logistics and back office: probably the most valuable, least discussed

The NSCAI lists predictive maintenance, supply-chain optimisation and paperwork automation. The Action Plan tells the Pentagon to automate workflows and keep them automated. There's little public measurement of results, but this is where large organisations usually get most of their value from new software. It's plausible and underexamined. Strangely, nobody's sales pitch leads with it, maybe because it doesn't sound like deterrence.

### 2f. Speeding up weapons production: a real problem with a self-serving fix

Palantir's CTO Shyam Sankar told Fox News (April 2026, while promoting his book *Mobilize*) that real deterrence isn't the stockpile but **the factory**. He said the US would have about **eight days** of weapons in an intense fight with China, and that AI can give US workers "superpowers" to outproduce China.

**The diagnosis holds up.** CSIS's independent wargames (Seth Jones, 2023, with no direct sponsor) found the US used up its entire stock of long-range anti-ship missiles in under a week in every iteration of a Taiwan war. It used more than 5,000 long-range missiles in three weeks. Those missiles take about two years to build, and the 2023 budget bought only 88 of the key type. CSIS also cites US government estimates that China is acquiring high-end weapons five to six times faster than the US. Sankar's quip that "we look like the Germans" (better weapons, too few of them) fits that evidence.

**The prescription doesn't follow.** The fixes CSIS lists are multi-year contracts so manufacturers will invest, second suppliers for components that only one company makes (one rocket motor, one turbofan maker, one titanium foundry), workforce, permits, and faster foreign arms sales. AI isn't on the list. Sankar's "AI fixes the factory" is the step where a real national problem turns into a product pitch.

### 2g. AI in high-level command decisions: the riskiest claim

The War Department memo funds AI agents "from campaign planning to kill chain execution". It tells staff to accept that the risks of moving too slowly outweigh the risks of "imperfect alignment", meaning AI that doesn't reliably do what's intended.

A 2024 study by Stanford, Georgia Tech, Northeastern and Hoover Institution researchers (Rivera et al.) ran five commercial models as national leaders in simulated crises. Every model escalated. The patterns were hard to predict, arms races emerged, and in rare runs models chose nuclear strikes. The authors caution that this is a simplified simulation. Chinese military writers raise the same worries (see Part 3).

**Verdict:** a real risk, acknowledged by serious people on both sides. The government's current documents push speed over it.

---

## Part 3. The industrial and economic competition

### 3a. Chips and export controls: the best-founded claim, betrayed by its own champions

The case:

- The US and its allies hold near-monopolies on key chipmaking tools (Action Plan).
- The world's most advanced chips come overwhelmingly from Taiwan (Superintelligence Strategy).
- Biden-era controls from 2022 forced Chinese AI firms onto older hardware (The Conversation).

The strongest evidence that this is a *military* issue and not just an industrial one comes from Chinese military procurement documents analysed by CSET (Georgetown):

- A PLA lab in 2025 asked for 16 Nvidia H100s, an export-controlled chip, to run DeepSeek and Alibaba models.
- PLA units are buying DeepSeek-based systems for translation, flight-path analysis, drone-swarm control, psychological operations and cyber.
- Many of those models were trained on US chips.

This directly contradicts Nvidia CEO Jensen Huang's claim, quoted by the CSET authors, that China doesn't need US chips to build its military.

**Now the twist.** In 2025 the administration that calls AI a race for survival:

- let Nvidia sell its H20 chip to China in return for 15% of revenue, and
- in December 2025, after Huang met the President, approved sales of the far more powerful **H200** in return for **25%** (CNN, The Conversation).

The Conversation's analyst described the high fence around sensitive technology turning into a turnstile with a price.

**Verdict:** the concern is sincere and well-founded, as the PLA documents show. The government's own conduct shows "national security" giving way to deal-making when a powerful company pushes. A skeptic can hold both facts at once.

**Incentive note:** Anthropic publicly backs strict chip controls. That's consistent with the evidence, but it also handicaps Chinese competitors. Nvidia wants the opposite because China is a huge market. Neither position can be read only off its merits.

### 3b. Energy and data centres: where "security" does the most lobbying

The Action Plan says US electricity capacity has stagnated since the 1970s while China built out its grid. That's a fair point about future AI demand. But look at the policies that ride on it:

- new exemptions from environmental review for data centres,
- a possible nationwide Clean Water Act permit for data centres,
- federal land for data centres, and
- the threat to limit federal funds to states whose AI rules the administration considers burdensome.

Critics quoted in Defense One called it a "wish list from Silicon Valley" (AI Now). They also warned it chills state-level work that actually helps national security (CSET's Mina Narayanan).

### 3c. How capable is China's military AI, really?

This is where independent research is most useful, and where official and corporate claims are most stretched.

- **What Chinese military writers say about themselves.** CSET's Sam Bresnick (2024) analysed 59 Chinese-language articles by PLA officers, defense engineers and academics. Many believe the **PLA is behind the US** in military AI. They describe:
  - military data still kept on paper, and no combat data because China hasn't fought a war in over four decades;
  - weak sensors, fragile communications and drone data links;
  - poor standards and weak testing.

  Many voice misgivings about using untrustworthy AI in war. Bresnick contrasts this with US alarm that China is overtaking America: the anxiety runs the other way across the Pacific. (One caveat: authors may be poorly informed or self-censoring.)
- **What the PLA is buying.** CSET's 2026 "Wish List" study finds the PLA pursuing AI in every domain. It focuses on decision-support tools (partly to make up for weaknesses it sees in its officer corps), on detecting US ships and submarines, and on countering US satellites. Contracts are small and fast, which suggests experimentation rather than deployment at scale.
- **The diffusion argument.** Jeffrey Ding (George Washington University) argues that what matters for a general-purpose technology isn't who invents first but who **adopts** it across the economy. On that measure China lags badly. Ding's advice is to keep calm and not overhype China. He also argues that claims US regulation will let China race ahead "do not hold water".
- **Where the skeptics have been overtaken.** Ding, writing with Helen Toner and Jenny Xiao in 2023, judged China "years, not months" behind on large language models. DeepSeek's January 2025 release surprised US policymakers, per a Cipher Brief report cited in AI Frontiers. Later analysts quoted there put the two countries roughly months apart on models.

**Synthesis:** China has largely caught up on *models*. The evidence suggests it trails on *turning AI into working military capability*, and leads on *mass-producing hardware*. That last point is awkward for the "AI deterrent" story. If China's edge is factories, the decisive bottleneck may be steel and rocket motors, not algorithms.

---

## Part 4. The deterrence claims

### 4a. Palantir: "the atomic age is ending"

I read the original post, as mirrored from X. Point 12 is a single sentence saying the atomic age of deterrence is ending and a new era built on AI is beginning. There's no argument, mechanism or evidence attached. Point 5 says AI weapons will be built anyway and the only question is who builds them, and that adversaries won't pause for "theatrical debates". Point 4 says hard power this century will be built on software.

**Why this is weak as an analytical claim:** deterrence works when the threat is *visible, credible and certain to be devastating*. Nuclear weapons are the extreme case: everyone knows what they do. AI is close to the opposite. Its effects are hidden, uncertain, hard for an opponent to verify, and only as good as the latest test. Those are poor properties for a deterrent. That may be why no government document I read makes Palantir's claim:

- The **NSCAI** wants the US to publicly affirm that **only humans** authorise nuclear use, and to press Russia and China to say the same.
- In November 2024 Presidents **Biden and Xi** jointly affirmed human control over nuclear decisions (NPR).
- In September 2026, Chinese scholars at Tsinghua and Peking universities argued that AI could *weaken* nuclear stability: compressing decision time, encouraging leaders to defer to machine outputs, and making a nuclear strike seem "clinical" (China Global South).

**The charitable reading:** *conventional* deterrence over Taiwan increasingly depends on software-driven sensing, targeting and cheap drones, so "hard power will be built on software" has a real kernel. The NSCAI itself calls AI R&D "investments in deterrence". But that supplements nuclear deterrence. It doesn't end it.

**Incentive check:**

- Palantir's US government revenue was **$809 million** of its **$1.935 billion** total in Q2 2026, about 42%, up 90% in a year (Palantir SEC filing).
- It built Maven, picking up the work after Google dropped it in 2018 following employee protests (Fortune).
- It won a $30 million no-bid immigration-enforcement contract (Fortune).
- Dave Karpf (Tech Policy Press) notes the stock traded at over 230 times earnings and was praised by the President on social media with its ticker.
- Bellingcat's Eliot Higgins put it simply: this is the public ideology of a company whose revenue depends on the politics it advocates (TechCrunch).

To be fair, Karp's views on defense predate the current boom, and Palantir took Maven when it was unpopular. The ideology may well be sincere. The trouble is that sincerity and self-interest point the same way here, so you can't use the claim's existence as evidence for it.

### 4b. The MAIM paper: a different, more serious claim

Hendrycks, Schmidt and Wang (March 2025) argue that if one country races for superintelligence, rivals will sabotage its project, through cyberattacks, insiders or even strikes on data centres, rather than accept being dominated. They say this threat already restrains everyone, and call it **Mutual Assured AI Malfunction**. They explicitly say it sits *alongside* nuclear MAD; it doesn't replace it. They pair it with sensible proposals that aren't really about deterrence: tracking chips, securing model weights, and blocking terrorists from AI-assisted bioweapons.

**The critics (all read in full):**

- **MIRI (David Abecassis):** there's no red line anyone can actually monitor. AI progress is gradual ("salami-slicing"), and capabilities emerge unpredictably. Sabotage only *delays*, so to be scary MAIM drifts toward threats of broader punishment, which is far more escalatory. MIRI proposes stopping advanced development much earlier, at the chip-factory and data-centre level.
- **Jason Ross Arnold (Virginia Commonwealth University, in AI Frontiers):** the "observability problem". Countries will misread each other: false alarms trigger attacks, missed signals allow breakouts. DeepSeek's surprise shows how badly intelligence agencies can misjudge progress.
- **RAND (Rehman, Mueller and Mazarr):** MAIM gets MAD backwards. MAD worked because *neither* side could pre-empt the other. MAIM is built on the ability to pre-empt, which creates first-strike incentives and a "hair-trigger" balance. Also, from Beijing's view the US already looks like it's racing for monopoly, yet nobody predicts Chinese strikes on US labs.
- **IAPS (Oscar Delaney):** breaks MAIM into three premises and estimates only about a 25% chance it actually plays out as described.

**Hendrycks' reply** argues that these instabilities come from the superintelligence race itself, not from MAIM. Strategic ambiguity deters too (no one tests exactly which cyberattack would trigger a nuclear response). And a recursion would take months, enough time to react. That's a fair point about where the danger comes from. It doesn't answer RAND's point that *institutionalising* pre-emption makes things worse.

**Verdict:** the whole debate is conditional on superintelligence being plausible soon. That's speculation, and the critics have the better of the argument about stability.

**Incentive check:**

- **Eric Schmidt** chaired the NSCAI. His drone company, Perennial Autonomy (formerly White Stork), won the deep-strike category of the War Department's drone competition in September 2026 (TechRadar). The MAIM paper recommends expanding drone manufacturing.
- **Alexandr Wang** founded Scale AI, which holds the prime contract for the Pentagon's flagship AI-planning program, Thunderforge (Scale's own announcement). He now runs Meta's superintelligence lab.
- **Hendrycks** advises xAI and Scale AI (his own website).
- **AI Frontiers**, which hosts both a critique and Hendrycks' reply, is edited by Hendrycks and funded by his Center for AI Safety (author bio on the site).

None of this proves bad faith. It does mean the authors aren't disinterested.

---

## Part 5. Does "it's just autocomplete" answer any of this?

**Mostly not, but it points at something real.**

- **It's technically true and beside the point.** Language models are trained to predict the next piece of text. That describes the training method, not what the system can do, much as "it's just electrons" says nothing about what a computer does.
- **Much military AI isn't autocomplete at all.** Maven's object recognition, drone guidance under jamming and logistics optimisation are different technologies. The quip doesn't touch them.
- **The "autocomplete" systems demonstrably do real work.** They found real software bugs in DARPA's challenge. They carried out most of a hacking campaign, by Anthropic's account. The PLA is buying them for cyber ranges and drone-swarm control.
- **What the skeptic should say instead:** these systems are *unreliable in ways that are hard to predict*. The evidence:
  - hallucinated credentials in the hacking case;
  - roughly 60% versus 84% accuracy for Maven against human analysts;
  - unpredictable escalation in wargames;
  - the Action Plan's own admission that how frontier models work inside is "poorly understood", which makes them hard to use where lives are at stake;
  - Chinese military authors calling current AI "weak".

  That's a much stronger objection, because it explains why "speed wins" policies are dangerous without having to deny the technology is powerful. It's also, notably, the line Anthropic took with the Pentagon.

---

## Part 6. Who has a stake in what

| Source | Stake | Signs of sincerity | Signs of self-interest |
|---|---|---|---|
| **Palantir** (post, Sankar, Karp) | About 42% of revenue from the US government; Maven; a very high stock valuation | Defense views predate the boom; took Maven when it was unpopular | Every claim maps onto a product; Sankar was promoting a book; the deterrence claim comes with no argument |
| **White House Action Plan** | Political "dominance" agenda; close ties to industry | Real export-control enforcement ideas; admits AI is unpredictable; funds safety evaluations | Deregulation and pressure on states framed as security; the administration then allowed H20 and H200 chip sales to China for a revenue cut |
| **War Department memo** | Budget; speed; contractor relations | Real concern about adoption lag | Demands "any lawful use" in contracts; downgrades testing as a "blocker"; used a foreign-adversary tool against a US firm. A district judge called that retaliation; the D.C. Circuit split 2–1 and upheld the designation in a parallel case |
| **NSCAI** | Chaired by Schmidt; commissioners included the CEOs of Oracle and AWS, Microsoft's chief scientific officer, Google Cloud's AI head, and In-Q-Tel's CEO | Insisted on human nuclear control, testing, civil liberties, talks with China | Recommendations (more cloud, more AI spending) align with members' businesses |
| **MAIM authors** | Schmidt (drones), Wang (Scale and Meta), Hendrycks (adviser to xAI and Scale) | Paper argues *against* a US "Manhattan Project" race | Recommends drone manufacturing; outlet funded by the author's own organisation |
| **Anthropic** (my maker) | Lobbying: $1.56M in Q1 2026 (NPR), a record $1.97M in Q2 2026 (Issue One); $20M to a political group (NPR); export controls hurt Chinese rivals | Accepted a government blacklisting rather than drop two restrictions | Itself frames AI as existentially important to defeating autocracies; gained a surge of consumer sign-ups from the fight |
| **OpenAI** | Allied super PAC network (Brockman plus Andreessen Horowitz), over $75M raised, mission statement invokes China (NPR) | Said it shared Anthropic's red lines | Replaced Anthropic in classified systems within hours; Altman later called the rushed deal "opportunistic and sloppy" |
| **Nvidia** | China sales | — | Its CEO met the President the week before the H200 approval (CNN); his claim that China's military doesn't need US chips is contradicted by PLA documents |
| **Think tanks** | CSET was founded with $55M from Open Philanthropy; the Special Competitive Studies Project, which praised the Action Plan, is a subsidiary of the Schmidt family foundation (its own website); the AI-safety groups (CAIS, MIRI, IAPS) share a mission focused on catastrophic risk | CSET's China work is careful and cuts both ways; CSIS's munitions report had no direct sponsor | MIRI wants AI development halted; safety groups benefit if AI is seen as world-changing |

**One pattern worth noticing (my inference, not a sourced finding):** both the boosters (Palantir, the labs, the War Department) and the catastrophists (MAIM, MIRI, the safety groups) share one premise: AI is an extraordinary, world-altering power. People with money at stake and people with a mission at stake both benefit from that premise. Well-funded voices arguing that military AI is merely *useful but ordinary* are scarce. Ding comes closest. That gap is a reason to stay skeptical of the shared premise, not just of either camp's conclusions.

---

## Part 7. The strongest case on each side

### The strongest skeptical case

The national-security frame is mostly being used to win domestic fights: against state AI laws (the Action Plan's funding threats; super PAC missions that invoke China), against environmental review, and against usage limits in contracts. When security and money conflicted over the H200, money won. When a company kept two narrow safety limits, the government reached for a tool meant for Chinese and Russian infiltrators, and a federal judge found the evidence of risk "slim".

The deterrence claim has no mechanism. The real military bottleneck, munitions, needs contracts and factories, not software. Chinese military authors say they're *behind*. The accuracy numbers we do have are mediocre. And the loudest advocates profit directly. On this view, AI is a useful tool being sold as a strategic revolution.

### The strongest case for the policy

The technology is already decisive in real wars. It picked targets in Iran, guided drones in Ukraine, and drove most of a state-backed hacking campaign. China's military is visibly buying it, including models trained on US chips and controlled US hardware it isn't supposed to have. China outbuilds the US in weapons and power plants. Adoption, not invention, decides military advantage, and the US military's habits of slow testing and slow procurement are a genuine weakness.

Even critics of the hype (CSIS, CSET, RAND) agree on chip controls, faster adoption and more industrial capacity. And if there's even a modest chance that advanced AI upsets strategic stability, as RAND, the MAIM critics and Chinese scholars all take seriously, then planning for it isn't hype. It's prudence.

---

## Part 8. What each side should take more seriously

**A skeptic should still take seriously:**

- PLA procurement documents showing China seeking controlled US chips and using US-trained models for military purposes. This is direct evidence, not industry spin.
- The munitions shortfall. It's real even if Palantir's fix isn't.
- That AI targeting and cyber operations are already used at scale. "Autocomplete" doesn't make that go away.
- That some industry players have paid real costs for restraint. Anthropic lost its government business. Hype alone doesn't explain that.
- That a superintelligence race, *if* it happens, would be destabilising. Serious deterrence scholars who reject MAIM still take that possibility seriously.

**A believer should be more doubtful of:**

- Any claim that AI replaces nuclear deterrence. Nobody in government says it, and the mechanism is missing.
- "China is overtaking us" claims. Chinese military writers think they're behind, and diffusion data favours the US.
- "Speed wins" doctrine that treats testing as a blocker. The NSCAI, the Action Plan's own text, the wargame studies and Chinese experts all warn against exactly that.
- Industry advice on chips. The administration's H200 decision shows how fast "security" yields to sales.
- Accuracy and reliability claims that come without public test data.

---

## Part 9. Established, contested, speculative

| Established | Contested | Speculative |
|---|---|---|
| AI is used in US intelligence, targeting and cyber operations at scale | Whether AI targeting reduces or increases civilian harm | AI replacing nuclear deterrence |
| Known Maven accuracy figures trail human analysts (as reported) | How large China's military-AI gap really is | Superintelligence arriving soon |
| The US would run short of key missiles within about a week in a Taiwan war (wargames) | Whether AI can meaningfully speed up munitions production | MAIM as a stable deterrence regime |
| The PLA is seeking controlled US chips and using US-trained models | Whether energy and permitting deregulation is a security necessity | AI-enabled "superweapons" such as a "transparent ocean" that reveals hidden submarines |
| The administration sold H20 and H200 chips to China for a revenue share | How much AI shifts the cyber balance between attack and defence | |
| AI companies sharply increased lobbying and political spending in 2025–26 | Whether the Anthropic blacklisting was lawful (courts split) | |
| LLM agents escalated unpredictably in research wargames | How far those wargame findings carry over to the real world | |

---

## Where to read further (in order)

1. **Anthropic's February 2026 statement plus NPR's August 2026 report on the court ruling.** The clearest window into what militaries actually want from AI and what a lab is willing to refuse (keeping my conflict of interest in mind).
2. **CSET, *China's Military AI Roadblocks* (Bresnick, 2024).** The best antidote to "China is ahead". It's short, and it's in Chinese military writers' own words.
3. **CSIS, *The U.S. Defense Industrial Base Is Not Prepared* (Jones, 2023).** The real deterrence problem, with no AI hype in it.
4. **RAND, *Seeking Stability in the Competition for AI Advantage* (2025).** A concise demolition of the MAD analogy by deterrence specialists.
5. **Rivera et al., *Escalation Risks from Language Models* (2024).** What happens when chatbots play statesman.
6. **Jeffrey Ding, *A Diffusion-Centered View of U.S.-China Technological Competition*.** The argument that adoption, not invention, decides who's ahead. Read it alongside news of DeepSeek, which partly overtook its 2023 conclusions.

---

## Appendix: how I read each source

"Full" means I read the whole text of the article or document, using the original publisher's page or PDF unless noted. "Part" means I read the sections listed. I paraphrased throughout and quoted only short phrases.

### Sources you listed

| Source | Status | Notes |
|---|---|---|
| Palantir 22-point post on X (18 April 2026) | **Full** | Read the complete text through an API mirror of the original post (fxtwitter), not x.com directly |
| TechCrunch, 19 April 2026 | **Full** | |
| Fortune, 22 April 2026 | **Full** | |
| Fox News, Sankar interview (1 April 2026) | **Full** | |
| Axios, Karp, 12 November 2025 | **Couldn't access** | Axios blocked automated access (403), and archive sites were unreachable from my environment. I didn't describe it from memory. I did read two *secondary* reports of Karp's Axios Show interview from 7 November 2025 (UnHerd, Gizmodo), but can't confirm they match the 12 November article |
| America's AI Action Plan (July 2025) | **Full** | Original 28-page PDF from whitehouse.gov. The Lawfare page is a short summary with the document embedded; also read |
| Department of War AI Strategy memo (9 January 2026) | **Full** | All 6 pages, from the scanned copy hosted by DMI/IDA. The original on media.defense.gov was located but blocked automated download (403) |
| NSCAI Final Report (2021) | **Part** | Read in full: executive summary, Chapter 3 (AI and Warfare), Chapter 4 (Autonomous Weapons, which contains the nuclear command-and-control material), and the commissioner biographies. Searched the full 756 pages for "deterrence" and read the relevant Blueprint passages. nscai.gov was unreachable, so I used the govinfo.gov copy |
| Superintelligence Strategy (arXiv 2503.05628, v2) | **Full** | Main text plus appendix FAQ and metrics; skipped the bibliography |
| MIRI, "Refining MAIM" (Abecassis) | **Full** | |
| AI Frontiers, "why-maim-falls-short…" | **Full** | That URL served Jason Ross Arnold's "Superintelligence Deterrence Has an Observability Problem" (August 2025) |
| AI Frontiers, "AI Deterrence Is Our Best Option" (Hendrycks) | **Full** | |
| Defense One, July 2025 | **Full** | |
| Tech Policy Press (Karpf), April 2026 | **Full** | |

### Additional sources I found

| Source | Status | Notes |
|---|---|---|
| CSIS, Jones, *U.S. Defense Industrial Base Is Not Prepared* (2023) | **Full** | Web feature version. For "Empty Bins" I read only the summary page; the full PDF wasn't read |
| CSET, *China's Military AI Roadblocks* (2024) | **Full** | Main text; not endnotes or the methodology appendix |
| CSET, *China's Military AI Wish List* (2026) | **Part** | Summary and takeaways page only |
| CSET/ETO blog, PLA procurement and US compute (McFaul & Bresnick, 2026) | **Full** | |
| Jeffrey Ding, Penn working paper | **Full** | |
| RAND commentary (Rehman, Mueller, Mazarr, 2025) | **Full** | |
| IAPS, "Crucial Considerations in ASI Deterrence" (Delaney, 2025) | **Full** | |
| Rivera et al., *Escalation Risks from Language Models* (2024) | **Part** | Abstract, introduction, results summary, discussion, limitations, conclusions; not the detailed methods or appendices |
| Anthropic, Department of War statement (26 February 2026) | **Full** | |
| Anthropic, AI-orchestrated espionage post (November 2025) | **Full** | The linked full PDF report wasn't read |
| TechCrunch, 26 and 27 February 2026 | **Full** | |
| NPR, 6 March 2026 | **Full** | |
| NPR, 28 August 2026 | **Full** | Broadcast transcript |
| ABC News, September 2026 | **Full** | |
| Just Security, supply-chain-risk analysis | **Full** | |
| NPR, Biden–Xi, November 2024 | **Full** | |
| China Global South, 25 September 2026 | **Full** | |
| Tech Brew, Maven in Iran (March 2026) | **Full** | |
| Kyiv Independent, Maven in Ukraine (April 2024) | **Full** | |
| Bloomberg, Maven feature | **Couldn't access** | 403 error. Its figures are cited above only as reported by the Kyiv Independent and Tech Brew |
| CyberScoop, DARPA AI Cyber Challenge (August 2025) | **Full** | |
| CNN, H200 decision (December 2025) | **Full** | |
| The Conversation (Gray), H200 | **Full** | |
| Palantir Q2 2026 results, SEC Exhibit 99.1 | **Part** | Highlights and outlook; not the financial tables |
| NPR, AI super PACs (June 2026) | **Full** | |
| Issue One, lobbying analysis (July 2026) | **Full** | |
| TechRadar, Schmidt's drone company (September 2026) | **Full** | |
| Georgetown, CSET founding announcement (2019) | **Full** | |
| Scale AI, Thunderforge announcement | **Full** | |
| Dan Hendrycks' homepage | **Full** | |
| Special Competitive Studies Project website (home and about pages) | **Part** | Checked for ownership only |
| Wikipedia, Alexandr Wang | **Part** | Career sections |
| UnHerd and Gizmodo, Karp on Axios (November 2025) | **Full** | Secondary coverage only |
| CNBC (2022) on Schmidt's investments; Forbes and Axios on AI lobbying; The Register on Anthropic's cyber report | **Couldn't access** | Blocked, or the page couldn't be parsed. Not used as sources |
