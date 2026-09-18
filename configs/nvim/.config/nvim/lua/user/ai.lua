local M = {}

local function keyword_from_context(ctx)
    if type(ctx) ~= "table" then
        return ""
    end

    local keyword = ctx.keyword or ctx.word or ""
    if keyword ~= "" then
        return keyword
    end

    if type(ctx.line) ~= "string" or type(ctx.bounds) ~= "table" or type(ctx.bounds.length) ~= "number" then
        return ""
    end

    local length = math.max(0, ctx.bounds.length)
    if length == 0 then
        return ""
    end

    return ctx.line:sub(math.max(1, #ctx.line - length + 1))
end

local function has_completed_item(items)
    for _, item in ipairs(items) do
        if not (item.data and item.data.loading) then
            return true
        end
    end

    return false
end

local function clean_completion_text(item)
    local text = item.label
    if item.textEdit and type(item.textEdit.newText) == "string" then
        text = item.textEdit.newText
    end

    text = text:gsub("```[%w-]*", "")
    text = text:gsub("```", "")
    text = text:gsub("^%s+", "")
    text = text:match("([^\r\n]+)") or text
    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function set_insert_at_cursor(item, ctx, text)
    if not item.textEdit or type(item.textEdit.newText) ~= "string" then
        return
    end

    item.textEdit.newText = text
    local cursor = type(ctx) == "table" and ctx.cursor or nil
    if type(cursor) ~= "table" then
        return
    end

    local position = {
        line = cursor[1] - 1,
        character = cursor[2],
    }
    item.textEdit.range = {
        start = vim.deepcopy(position),
        ["end"] = vim.deepcopy(position),
    }
end

local function transform_items(ctx, items)
    local keyword = keyword_from_context(ctx)
    local completion_ready = has_completed_item(items)
    local transformed = {}

    for _, item in ipairs(items) do
        if item.data and item.data.loading then
            if not completion_ready then
                item.filterText = keyword
                table.insert(transformed, item)
            end
        else
            local text = clean_completion_text(item)
            if text ~= "" and text ~= "```" then
                set_insert_at_cursor(item, ctx, text)
                item.label = text
                item.filterText = (keyword ~= "" and keyword) or text
                table.insert(transformed, item)
            end
        end
    end

    return transformed
end

function M.setup(blink_ai)
    blink_ai.setup({
        provider = "fim",
        providers = {
            fim = {
                model = "qwen2.5-coder:3b",
                endpoint = "http://127.0.0.1:11434/api/generate",
                fim_tokens = {
                    prefix = "<|fim_prefix|>",
                    suffix = "<|fim_suffix|>",
                    middle = "<|fim_middle|>",
                },
                extra_body = {
                    raw = true,
                    options = {
                        temperature = 0,
                        num_predict = 24,
                        stop = {
                            "<|fim_prefix|>",
                            "<|fim_suffix|>",
                            "<|fim_middle|>",
                            "<|endoftext|>",
                        },
                    },
                },
            },
        },
        debounce_ms = 100,
        max_tokens = 24,
        line_max_tokens = 24,
        completion_scope = "line",
        ui = {
            loading_placeholder = {
                enabled = true,
                watchdog_ms = 5000,
            },
        },
        stats = {
            enabled = true,
        },
    })
end

function M.blink_provider()
    return {
        name = "AI",
        module = "blink-ai",
        async = false,
        timeout_ms = 15000,
        min_keyword_length = 0,
        score_offset = -10,
        transform_items = transform_items,
    }
end

function M.sort_ai_last(a, b)
    local a_is_ai = a.source_id == "ai"
    local b_is_ai = b.source_id == "ai"
    if a_is_ai ~= b_is_ai then
        return not a_is_ai
    end
end

return M
