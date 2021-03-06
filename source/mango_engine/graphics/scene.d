/*
 *  BSD 3-Clause License
 *  
 *  Copyright (c) 2016, Mango-Engine Team
 *  All rights reserved.
 *  
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *  
 *  * Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *  
 *  * Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *  
 *  * Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 *  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 *  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 *  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 *  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module mango_engine.graphics.scene;

import mango_engine.game;
import mango_engine.graphics.model;
import mango_engine.graphics.texture;
import mango_engine.graphics.shader;

import mango_stl.misc;

import std.exception;

/// A basic scene which can have multiple models. 
class Scene {
    private shared GameManager _game;
    private shared Model[string] _models;

    @property Model[string] models() @trusted nothrow { return cast(Model[string]) _models; }
    @property GameManager game() @trusted nothrow { return cast(GameManager) _game;}

    this(GameManager game) @trusted nothrow {
        this._game = cast(shared) game;
    }

    void addModel(Model model) @trusted {
        enforce(!(model.name in this.models), new Exception("Model \"" ~ model.name ~ "\" is already in this scene!"));

        synchronized(this) {
            _models[model.name] = cast(shared) model;
        }
    }

    void removeModel(in string modelName) @safe {
        enforce(modelName in this.models, new Exception("Model \"" ~ modelName ~ "\" is already in this scene!"));

        synchronized(this) {
            _models.remove(modelName);
        }
    }
}