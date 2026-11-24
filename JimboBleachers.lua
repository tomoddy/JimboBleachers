--- Jimbo Bleachers
--- Once you hold more than ROW_SIZE Jokers, the Joker area splits into rows.
--- Rows = ceil(jokers / ROW_SIZE), Jokers are spread evenly with extras on the top rows
--- (11 -> 6+5, 21 -> 7+7+7), and cards scale to 1/rows so the area keeps its height.
--- Card order (and so trigger order) is reading order: top row left to right, then the next row.
--- This is layout only; scoring is untouched.

SMODS.Atlas({
    key = "modicon",
    path = "modicon.png",
    px = 34,
    py = 34,
})

local ROW_SIZE = 10

--- How many rows, and how many Jokers in each (extras go to the top rows).
local function row_layout(count)
    local rows = math.ceil(count / ROW_SIZE)
    local base = math.floor(count / rows)
    local extra = count % rows
    local sizes = {}
    for r = 1, rows do
        sizes[r] = base + (r <= extra and 1 or 0)
    end
    return rows, sizes
end

local function set_scale(card, scale)
    if not card.bleachers_base then
        card.bleachers_base = { w = card.T.w, h = card.T.h }
    end
    card.T.w = card.bleachers_base.w * scale
    card.T.h = card.bleachers_base.h * scale
end

local function restore_size(card)
    if card.bleachers_base then
        card.T.w = card.bleachers_base.w
        card.T.h = card.bleachers_base.h
        card.bleachers_base = nil
    end
    card.bleachers_row = nil
end

local function align_bleachers(area)
    local cards = area.cards
    local rows, sizes = row_layout(#cards)
    local scale = 1 / rows
    local card_w = area.card_w * scale
    local row_h = area.T.h / rows
    local wobble = G.SETTINGS.reduced_motion and 0 or 1

    -- Place every card in its slot by index (dragged cards keep following the cursor)
    local k = 0
    for r = 1, rows do
        local m = sizes[r]
        local row_centre = area.T.y + row_h * (r - 0.5)
        for j = 1, m do
            k = k + 1
            local card = cards[k]
            set_scale(card, scale)
            if not card.states.drag.is and not card.disable_align then
                card.bleachers_row = r
                card.T.r = 0.1 * (-m / 2 - 0.5 + j) / m + wobble * 0.02 * math.sin(2 * G.TIMERS.REAL + card.T.x)
                if m > 1 then
                    card.T.x = area.T.x + (area.T.w - card_w) * ((j - 1) / (m - 1)) + 0.5 * (card_w - card.T.w)
                else
                    card.T.x = area.T.x + area.T.w / 2 - card_w / 2 + 0.5 * (card_w - card.T.w)
                end
                local highlight_height = card.highlighted and (G.HIGHLIGHT_H / 2) * scale or 0
                card.T.y = row_centre - card.T.h / 2 - highlight_height
                    + wobble * 0.03 * scale * math.sin(0.666 * G.TIMERS.REAL + card.T.x)
                card.T.x = card.T.x + card.shadow_parrallax.x / 30
            end
        end
    end

    -- Sort into reading order. A dragged card's row comes from where it's being held,
    -- so dropping it into another row moves it there in the order.
    local keys = {}
    for _, card in ipairs(cards) do
        local row = card.bleachers_row
        if card.states.drag.is or not row then
            local centre_y = card.T.y + card.T.h / 2
            row = math.max(1, math.min(rows, math.floor((centre_y - area.T.y) / row_h) + 1))
        end
        local pinned = (card.pinned and not card.ignore_pinned) and (card.sort_id or 0) * 1e5 or 0
        keys[card] = row * 1000 + card.T.x + card.T.w / 2 - pinned
    end
    table.sort(cards, function(a, b) return keys[a] < keys[b] end)

    for i, card in ipairs(cards) do
        card.rank = i
    end
    if area.children.view_deck then
        area.children.view_deck:set_role({ major = cards[1] or area })
    end
end

local align_cards_ref = CardArea.align_cards
function CardArea:align_cards()
    if self == G.jokers and self.config.type == "joker" and #self.cards > ROW_SIZE then
        return align_bleachers(self)
    end
    if self == G.jokers then
        for _, card in ipairs(self.cards) do
            if card.bleachers_base then
                restore_size(card)
            end
        end
    end
    return align_cards_ref(self)
end

-- A Joker that leaves the area while still on screen goes back to full size
local remove_card_ref = CardArea.remove_card
function CardArea:remove_card(card, discarded_only)
    local removed = remove_card_ref(self, card, discarded_only)
    if self == G.jokers and removed and removed.bleachers_base and not removed.removed then
        restore_size(removed)
    end
    return removed
end
