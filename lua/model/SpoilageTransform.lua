-- This file is part of Dana.
-- Copyright (C) 2024 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
--
-- Dana is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Dana is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with Dana.  If not, see <https://www.gnu.org/licenses/>.

local AbstractTransform = require("lua/model/AbstractTransform")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local ProductAmount = require("lua/model/ProductAmount")

local Metatable

-- Transform associated to item spoilage.
--
-- Example: 'raw-fish' -> 'spoiled-raw-fish'.
--
-- Inherits from AbstractTransform.
--
-- RO Fields:
-- * inputItem: Item prototype that is the input of this transform.
-- * spoilResult: Prototype of the resulting spoiled item.
--
local SpoilageTransform = ErrorOnInvalidRead.new{
    -- Restores the metatable of a SpoilageTransform object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractTransform.setmetatable(object, Metatable)
    end,

    -- Creates a new SpoilageTransform if the item defines spoilage metadata.
    --
    -- Args:
    -- * itemIntermediate: Factorio prototype of an item.
    -- * intermediatesDatabase: Database containing the Intermediate objects to use for this transform.
    --
    -- Returns: The new SpoilageTransform if the item spoils. Nil otherwise.
    --
    tryMake = function(itemIntermediate, intermediatesDatabase)
        local result = nil
        local rawPrototype = itemIntermediate.rawPrototype
        local spoil_result = rawPrototype.spoil_result
        if spoil_result then
            local productSpec = spoil_result
            if type(spoil_result) == "string" then
                productSpec = {name = spoil_result, type = "item"}
            end

            local product = intermediatesDatabase:getIngredientOrProduct(productSpec)
            local spoilAmount = rawPrototype.spoil_amount or productSpec.amount or 1
            result = AbstractTransform.new({
                type = "spoilage",
                inputItem = itemIntermediate,
                spoilResult = productSpec,
            }, Metatable)
            result:addIngredient(itemIntermediate, spoilAmount)
            result:addProduct(product, ProductAmount.makeConstant(productSpec.amount or 1))
        end
        return result
    end,

    -- LocalisedString representing the type.
    TypeLocalisedStr = AbstractTransform.makeTypeLocalisedStr("spoilageType"),
}

-- Metatable of the SpoilageTransform class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractTransform;generateSpritePath().
        generateSpritePath = function(self)
            return AbstractTransform.makeSpritePath("item", self.spoilResult)
        end,

        -- Implements AbstractTransform:getTypeStr().
        getShortName = function(self)
            return self.inputItem.rawPrototype.localised_name
        end,

        -- Implements AbstractTransform:getTypeStr().
        getTypeStr = function(self)
            return SpoilageTransform.TypeLocalisedStr
        end,
    }
}
setmetatable(Metatable.__index, {__index = AbstractTransform.Metatable.__index})

return SpoilageTransform
