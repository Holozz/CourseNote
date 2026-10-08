## 流程
- 场景：多智能体旅行规划系统——模拟一个 AI 旅行规划团队协作制定旅行方案的过程，涵盖从需求收集到方案审查的完整链路
- 智能体（5 个）：
	- Planner（旅行规划师 🧭）：主持人角色，CoT 推理，协调团队进度，汇总最终方案
	- DestinationExpert（目的地专家 🌍）：ReAct 推理，调用搜索工具挖掘目的地信息并推荐
	- BudgetAnalyst（预算分析师 💰）：计算旅行各项费用，提供多档次预算方案
	- LocalGuide（本地向导 🗺️）：提供地道建议、文化礼仪和避坑指南
	- ReviewSynthesizer（综合评估师 📋）：Reflection 推理，审查方案完整性并给出改进意见
- 图结构：基于 LangGraph 构建有向循环图，发言顺序依次为 Planner → DestinationExpert → BudgetAnalyst → LocalGuide → ReviewSynthesizer → Planner（循环），共 2 轮 10 次发言 + 1 次总结
- 记忆系统：短期记忆（每 Agent 保留最近 5 条消息）+ 长期记忆（结构化旅行知识库：目的地、预算、偏好、进度追踪）
- 工具（3 种）：`search_destination_info`（搜索目的地信息）、`calculate_travel_cost`（计算旅行费用）、`store_travel_note`（存储关键笔记），全部通过 ChatOpenAI 的 `bind_tools()` 绑定至模型并发起真实调用
## 实验原理
### 1. 多智能体系统（Multi-Agent System, MAS）
多智能体系统由多个自主的智能体（Agent）组成，每个 Agent 感知环境并采取行动以实现自身目标。在旅行规划场景中，各 Agent 扮演不同角色，通过**分工协作**完成单一 Agent 难以胜任的复杂任务。关键特征：
- 异质性：各 Agent 拥有独立的系统提示词（System Prompt），对同一任务从不同专业视角切入
- 自治性：每个 Agent 独立调用 LLM 生成回复，具备独立的记忆上下文
- 协调性：通过 LangGraph 定义的有向图控制发言顺序，Planner 作为主持人汇总进展并推动流程
### 2. 推理/规划方法
#### 2.1 链式思维推理（Chain-of-Thought, CoT）
Planner 使用 CoT 推理，按固定模板分步思考：
```
第1步：回顾当前旅行规划进展到哪一步了
第2步：各成员已经提供了哪些信息？
第3步：下一步需要什么？需要记录什么？
第4步：形成你的发言
```
CoT 通过显式的中间推理步骤引导 LLM 产生更准确、可解释的回复，特别适合需要多步分析和综合的任务
#### 2.2 ReAct（Reasoning + Acting）
DestinationExpert 使用 ReAct 推理框架，交替进行推理（Reasoning）和行动（Acting）：
```
思考：根据旅行需求，我需要搜索什么目的地信息？
搜索：调用 search_destination_info 搜索相关信息
分析：搜索结果说明了什么？是否匹配用户需求？
推荐：基于分析结果，给出具体的目的地推荐
```
ReAct 通过**推理→行动→观察**循环，让 Agent 能利用外部工具获取实时信息来辅助决策，克服纯 LLM 推理的知识截止和幻觉问题
#### 2.3 Reflection（反思式推理）
ReviewSynthesizer 使用 Reflection 推理，对已有方案进行批判性审查
```
审查：当前旅行方案的完整度如何？逐项检查
质疑：有哪些不合理之处或遗漏？
风险：存在什么潜在问题？
完善建议：如何改进方案？
```
Reflection 让 Agent 对自身或他人的输出进行多维度评估，识别缺陷并提出改进，类似于人类写作中的"自我审稿"机制
### 3. 记忆机制
#### 3.1 短期记忆（Short-Term Memory）
每个 Agent 维护一个**最近 5 条消息**的滑动窗口缓冲区：
```python
def short_term_context(self, st_memory: list[dict]) -> str:
    recent = st_memory[-5:] if len(st_memory) > 5 else st_memory
    if not recent:
        return "（暂无近期讨论记录）"
    return "\n".join(f"【{m['speaker']}】{m['content'][:200]}" for m in recent)
```
短期记忆为 Agent 提供紧邻上下文，确保回应的连贯性和话题相关性。容量限制为 5 条以实现有限注意力
#### 3.2 长期记忆（Long-Term Memory）
长期记忆以结构化字典形式存储，包含：
- `trip_summary`：旅行方案概述
- `destination`、`budget`、`preferences`：关键决策参数
- `notes`：各 Agent 的历史记录
- `plan_progress`：团队任务完成状态（目的地研究、预算分析、本地建议、方案审查）
长期记忆在整个会话周期内持久存在，供所有 Agent 共享
### 4. 工具调用机制
系统通过 LangChain 的 `bind_tools()` 将工具定义绑定到 ChatOpenAI 模型。调用流程为：
```
User Prompt → LLM(with tools) → 输出 tool_calls → 执行工具 → 
Tool结果回传 LLM → LLM 基于工具结果生成最终回复
```
核心实现：
```python
def invoke_with_tools(prompt, agent):
    local_model = model.bind_tools(tool_list)
    resp = local_model.invoke([HumanMessage(content=prompt)])
    if resp.tool_calls:
        messages.append(AIMessage(tool_calls=resp.tool_calls))
        tool_msgs = execute_tool_calls(resp.tool_calls)
        messages.extend(tool_msgs)
        final_resp = model.invoke(messages)
        return final_resp.content
    return resp.content
```
## 伪代码

```text
main():
    // [1] 初始化
    初始化 DashScope/OpenAI 模型 (qwen3.6-flash, temperature=0.7)
    创建 5 个 TravelAgent 实例 (Planner, DestinationExpert, BudgetAnalyst, LocalGuide, ReviewSynthesizer)

    // [2] 工具定义
    @tool search_destination_info(query):    // 搜索目的地信息
        从 knowledge_base 匹配返回
    @tool calculate_travel_cost(expression): // 计算旅行费用
        解析表达式并返回计算结果
    @tool store_travel_note(key, category):  // 存储关键笔记
        返回记录确认消息

    // [3] 构建图
    graph ← StateGraph(TravelState)
    for agent in all_agents:
        graph.add_node(agent.name, agent_node)
        graph.add_conditional_edges(agent.name, router)
    graph.set_entry_point("Planner")
    graph ← graph.compile()

    // [4] 初始化状态
    state ← TravelState(
        messages=[], current_agent="Planner", round=0,
        max_rounds=2, terminated=False,
        short_term_memory={每个 agent: []},
        long_term_memory={初始默认值}
    )

    // [5] 执行图（流式运行）
    for step in graph.stream(state):
        node_name, updates ← step
        if updates.messages 非空:
            last ← updates.messages[-1]
            if terminated:
                打印总结陈词，输出最终统计
                return
            打印当前发言者、轮次、内容

    // [6] 保存完整输出
    将全部日志写入 travel_plan_output.txt
```

## 代码展示
- 工具定义：
	- `search_destination_info`：搜索工具，用硬编码实现知识库匹配
		
		```python
		@tool
		def search_destination_info(query: str) -> str:
		    """搜索目的地相关信息，包括景点、美食、文化、天气、交通等"""
		    knowledge_base = {...}
		    for key, value in knowledge_base.items():
		        if key in query.lower():
		            return value
		    return (
		        f"关于「{query}」的旅行信息：该目的地拥有丰富的旅游资源，"
		        f"建议提前了解当地签证要求、最佳旅行季节和预算规划。"
		    )	
		```
		
	- `calculate_travel_cost`：计算工具，用数学公式计算费用
		
		```python
		@tool
		def calculate_travel_cost(expression: str) -> str:
	    """计算旅行费用，支持加减乘除和百分比运算"""
	    if not re.match(r'^[\d+\-*/.%() ]+$', expression):
	        return "不支持的表达式格式，请使用数字和运算符 + - * / %"
	    try:
	        expr = expression.replace("%", "/100.0")
	        result = eval(expr)
	        return f"💰 费用计算结果：{expression} = {result:.2f}（单位：元/当地货币）"
	    except Exception as e:
	        return f"计算出错：{e}"
		```
		
	- `store_travel_note`：笔记，记录关键决策
		
		```python
		@tool
		def store_travel_note(key_point: str, category: str) -> str:
	    """存储旅行计划中的关键信息，category 可选值：destination / budget / preference / tip"""
	    return f"📌 已记录【{category}】信息：{key_point}"
		```

- Agent 基类：管理角色标识、推理方式标记、短期记忆格式化和长期记忆结构化读取（按阵营/角色筛选已有论点）

    ```python file:TravelPlanner.py
    class TravelAgent:
        def __init__(self, name, title, system_prompt,
                     use_cot=False, use_react=False, use_reflection=False):
            self.name = name
            self.title = title
            self.system_prompt = system_prompt
            self.use_cot = use_cot
            self.use_react = use_react
            self.use_reflection = use_reflection

        def short_term_context(self, st_memory):
            recent = st_memory[-5:] if len(st_memory) > 5 else st_memory
            return "\n".join(f"【{m['speaker']}】{m['content'][:200]}" for m in recent)

        def long_term_context(self, lt_memory):
            parts = []
            if lt_memory.get("trip_summary"):
                parts.append(f"📋 旅行方案概述：{lt_memory['trip_summary']}")
            # ... 目的地、预算、偏好、笔记、进度等
            return "\n".join(parts) if parts else "（暂无长期记录）"
    ```
	随后根据基类创建5个不同的Agent实例，使用不同的工具或者推理方法

- **模型绑定与工具调用**：ChatOpenAI 通过 `bind_tools()` 注册工具，模型自主决定何时调用；执行工具结果后二次调用模型生成最终回复

    ```python file:TravelPlanner.py
    model = ChatOpenAI(
        model="qwen3.6-flash",
        base_url="https://ws-.../compatible-mode/v1",
        api_key="sk-ws-...",
        temperature=0.7,
    )
    model_with_tools = model.bind_tools(list(TOOL_MAP.values()))

    def invoke_with_tools(prompt, agent):
        messages = [HumanMessage(content=prompt)]
        local_model = model_with_tools if not agent.use_react else model.bind_tools([search_destination_info, store_travel_note])
        resp = local_model.invoke(messages)

        if resp.tool_calls:
            messages.append(AIMessage(content=resp.content or "", tool_calls=resp.tool_calls))
            messages.extend(execute_tool_calls(resp.tool_calls))
            final_resp = model.invoke(messages)
            if final_resp.content:
                return final_resp.content

        if not resp.content:  # 保底重试
            retry = model.invoke([HumanMessage(content=prompt + "\n\n请直接输出你的发言，不要调用工具。")])
            if retry.content:
                return retry.content
        return resp.content or "(本次发言为空)"
    ```

- **三种不同推理方式的提示词构造**：CoT 引导分步推理，ReAct 规定思考→搜索→分析→推荐流程，Reflection 要求审查→质疑→风险→完善

    ```python file:TravelPlanner.py
    if agent.use_cot:
        prompt = base_prompt + """
        请按链式思维（CoT）逐步推理：
        第1步：回顾当前旅行规划进展到哪一步了
        第2步：各成员已经提供了哪些信息？
        第3步：下一步需要什么？需要记录什么？
        第4步：形成你的发言"""

    elif agent.use_react:
        prompt = base_prompt + """
        请严格按 ReAct 流程工作：
        🤔 思考：根据旅行需求，我需要搜索什么目的地信息？
        🔍 搜索：调用 search_destination_info 搜索相关信息
        📊 分析：搜索结果说明了什么？
        💡 推荐：基于分析结果，给出具体的目的地推荐"""

    elif agent.use_reflection:
        prompt = base_prompt + """
        请按 Reflection（反思式审查）流程工作：
        🔍 审查：当前旅行方案的完整度如何？
        ❓ 质疑：有哪些不合理之处或遗漏？
        ⚠️ 风险：存在什么潜在问题？
        💡 完善建议：如何改进方案？"""
    ```

- LangGraph 图构建与路由：每个 Agent 为一个节点，所有节点出边由 `router` 函数按 `SPEAKER_ORDER` 循环路由到下一发言者

    ```python file:TravelPlanner.py
    SPEAKER_ORDER = ["Planner", "DestinationExpert", "BudgetAnalyst", "LocalGuide", "ReviewSynthesizer"]

    def router(state):
        if state["terminated"]:
            return END
        idx = SPEAKER_ORDER.index(state["current_agent"])
        nxt = (idx + 1) % len(SPEAKER_ORDER)
        return SPEAKER_ORDER[nxt]

    def build_travel_graph():
        workflow = StateGraph(TravelState)
        for agent in all_agents:
            workflow.add_node(agent.name, _make_node_fn(agent))
        for agent in all_agents:
            workflow.add_conditional_edges(agent.name, router)
        workflow.set_entry_point("Planner")
        return workflow.compile()
    ```

- 长期记忆更新逻辑：Planner 每次发言后根据消息历史更新 `plan_progress`，追踪各成员的任务完成状态

    ```python file:TravelPlanner.py
    if agent.name == "Planner":
        lt["trip_summary"] = content[:150]
        spoken = {m["speaker"] for m in state["messages"]}
        lt["plan_progress"] = {
            "目的地研究": "DestinationExpert" in spoken,
            "预算分析": "BudgetAnalyst" in spoken,
            "本地建议": "LocalGuide" in spoken,
            "方案审查": "ReviewSynthesizer" in spoken,
        }
    ```

## 创新点
1. 可以自定义输入，在 `TravelPlanner.py`中 `main()`的`user_requirement`进行调整
2. 三种推理方法融合：在同一系统中同时实现了 CoT（Planner）、ReAct（DestinationExpert）和 Reflection（ReviewSynthesizer）三种推理范式，各 Agent 按角色适配最合适的推理策略，而非"一刀切"使用同一种方法
3. 短期+长期双层记忆架构：短期记忆以滑动窗口（5 条）提供紧邻上下文；长期记忆以结构化字典（目的地、预算、偏好、进度）跨轮次持久化，解决纯 LLM 上下文的"遗忘"问题
4. 三种工具绑定与真实调用：搜索（知识库匹配）、计算（表达式求值）、笔记（文本存储）三类工具全部通过 `ChatOpenAI.bind_tools()` 绑定到模型，Agent 在推理过程中自主决定何时调用工具，而非硬编码触发
5. 工具调用保底机制：当模型调用工具后二次回复为空时，自动用"禁止调工具"提示重试一次，避免模型"沉默"导致的发言缺失
6. Reflection 批判性审查：ReviewSynthesizer 按"审查→质疑→风险→完善"四步框架对整份方案做系统性评审，模拟学术同行评议机制，确保方案质量
7. 完整输出持久化：运行日志同步写入终端和文件 `travel_plan_output.txt`，方便事后查阅完整内容
8. 利用AI完善整体框架以及推理流程，更合理的保存消息和轮流使用Agent
## 实验结果
见于输出文件 `travel_plan.md`