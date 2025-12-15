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

local IntermediatesDatabase = require("lua/model/IntermediatesDatabase")
local LuaGameScript = require("lua/testing/mocks/LuaGameScript")
local ProductAmount = require("lua/model/ProductAmount")
local ProductData = require("lua/model/ProductData")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local SpoilageTransform = require("lua/model/SpoilageTransform")

describe("SpoilageTransform", function()
    local gameScript
    local intermediates
    setup(function()
        gameScript = LuaGameScript.make{
            item = {
                spoiled = {type = "item", name = "spoiled"},
                fresh = {
                    type = "item",
                    name = "fresh",
                    spoil_result = {type = "item", name = "spoiled", amount = 2},
                    spoil_amount = 2,
                },
                stable = {type = "item", name = "stable"},
            },
        }
        intermediates = IntermediatesDatabase.new()
        intermediates:rebuild(gameScript)
    end)

    describe(".tryMake()", function()
        it("-- spoil_result", function()
            local fresh = intermediates.item.fresh
            local spoiled = intermediates.item.spoiled
            local object = SpoilageTransform.tryMake(fresh, intermediates)
            assert.are.same(object, {
                ingredients = {
                    [fresh] = 2,
                },
                inputItem = fresh,
                localisedName = {
                    "dana.model.transform.name",
                    {"dana.model.transform.spoilageType"},
                    fresh.rawPrototype.localised_name,
                },
                products = {
                    [spoiled] = ProductData.make(ProductAmount.makeConstant(2)),
                },
                type = "spoilage",
                spoilResult = fresh.rawPrototype.spoil_result,
                spritePath = spoiled.spritePath,
            })
        end)

        it("-- no spoil_result", function()
            local stable = intermediates.item.stable
            local object = SpoilageTransform.tryMake(stable, intermediates)
            assert.is_nil(object)
        end)
    end)

    describe(".setmetatable()", function()
        local object = SpoilageTransform.tryMake(intermediates.item.fresh, intermediates)
        SaveLoadTester.run{
            objects = {
                intermediates = intermediates,
                object = object,
            },
            metatableSetter = function(objects)
                IntermediatesDatabase.setmetatable(objects.intermediates)
                SpoilageTransform.setmetatable(objects.object)
            end,
        }
    end)
end)
