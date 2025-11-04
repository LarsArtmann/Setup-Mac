# BehaviorDrivenTests.nix - BDD INFRASTRUCTURE FOR CONFIGURATION SYSTEM
# TYPE-SAFE BEHAVIOR-DRIVEN DEVELOPMENT TESTING

{ lib, pkgs, State, Types, Validation, ... }:

let
  # BDD TEST RUNNER - TYPE-SAFE TEST EXECUTION
  BDDTestRunner = { tests, systemConfig }:
    let
      runTest = test:
        let
          scenario = test.scenario or "Unknown scenario";
          given = test.given or {};
          when = test.when or [];
          then = test.then or [];

          # Execute test steps
          givenResult = lib.evalModules {
            modules = [{ inherit given; }];
            specialArgs = { inherit lib pkgs systemConfig; };
          };

          whenResult = lib.foldl' (acc: step:
            lib.evalModules {
              modules = [acc.config step];
              specialArgs = { inherit lib pkgs systemConfig; };
            }
          ) givenResult when;

          thenResult = lib.foldl' (acc: step:
            lib.evalModules {
              modules = [acc.config step];
              specialArgs = { inherit lib pkgs systemConfig; };
            }
          ) whenResult then;

          # Validate test expectations
          validateExpectations = expectations:
            let
              validateExpectation = exp:
                let
                  actual = exp.actual or thenResult.config.${exp.field} or null;
                  expected = exp.expected;
                  matches = actual == expected;
                in {
                  description = exp.description or "";
                  actual = actual;
                  expected = expected;
                  matches = matches;
                  passed = matches;
                };

              validatedExpectations = map validateExpectation expectations;
              allPassed = lib.all (exp: exp.passed) validatedExpectations;
              failedExpectations = lib.filter (exp: !exp.passed) validatedExpectations;

            in {
              expectations = validatedExpectations;
              allPassed = allPassed;
              failedCount = builtins.length failedExpectations;
              failedExpectations = failedExpectations;
            };

          testResult = {
            scenario = scenario;
            given = given;
            when = when;
            then = then;
            result = thenResult.config;
            validation = validateExpectations test.expectations or [];
            passed = (validateExpectations test.expectations or []).allPassed;
          };

        in testResult;

      runResults = map runTest tests;
      passedTests = lib.filter (t: t.passed) runResults;
      failedTests = lib.filter (t: !t.passed) runResults;

    in {
      tests = runResults;
      passed = passedTests;
      failed = failedTests;
      total = builtins.length runResults;
      passRate = (builtins.length passedTests) * 100.0 / (builtins.length runResults);
    };

  # WRAPPER SYSTEM BDD TESTS - COMPREHENSIVE TESTS
  WrapperSystemTests = systemConfig: [
    {
      scenario = "CLI Tool Wrapper Creation";
      given = {
        wrapperType = "cli-tool";
        package = pkgs.starship;
        config = {
          additionalPackages = [pkgs.fish];
          aliasName = "sp";
        };
      };
      when = [
        { name = "Create CLI wrapper"; action = "generateWrapper"; }
        { name = "Validate wrapper"; action = "validateWrapper"; }
      ];
      then = [];
      expectations = [
        {
          description = "Wrapper should be created successfully";
          field = "wrapper.success";
          expected = true;
        }
        {
          description = "Wrapper should have correct package";
          field = "wrapper.package";
          expected = pkgs.starship;
        }
        {
          description = "Wrapper should include additional packages";
          field = "wrapper.additionalPackages";
          expected = [pkgs.fish];
        }
      ];
    }
    {
      scenario = "Path Consistency Validation";
      given = {
        paths = State.Paths;
        system = systemConfig;
      };
      when = [
        { name = "Validate path consistency"; action = "validatePaths"; }
      ];
      then = [];
      expectations = [
        {
          description = "All paths should exist";
          field = "pathValidation.allValid";
          expected = true;
        }
        {
          description = "No missing paths should exist";
          field = "pathValidation.missingPaths";
          expected = [];
        }
      ];
    }
    {
      scenario = "Package Platform Compatibility";
      given = {
        packages = [pkgs.starship pkgs.netdata pkgs.adguardian];
        system = systemConfig;
      };
      when = [
        { name = "Validate package compatibility"; action = "validatePackages"; }
      ];
      then = [];
      expectations = [
        {
          description = "All packages should be compatible with current system";
          field = "packageValidation.totalValid";
          expected = true;
        }
      ];
    }
    {
      scenario = "State Consistency Across Modules";
      given = {
        system = systemConfig;
      };
      when = [
        { name = "Check environment.nix paths"; action = "validateEnvironmentPaths"; }
        { name = "Check flake.nix paths"; action = "validateFlakePaths"; }
        { name = "Check manual-linking script"; action = "validateManualLinking"; }
      ];
      then = [];
      expectations = [
        {
          description = "All modules should use consistent paths";
          field = "stateValidation.consistency";
          expected = true;
        }
      ];
    }
    {
      scenario = "External Tool Integration";
      given = {
        externalTools = systemConfig.externalTools;
        system = systemConfig;
      };
      when = [
        { name = "Initialize external tools"; action = "initExternalTools"; }
        { name = "Validate external tools"; action = "validateExternalTools"; }
      ];
      then = [];
      expectations = [
        {
          description = "All external tools should be available";
          field = "externalTools.available";
          expected = true;
        }
        {
          description = "Crush should be properly integrated";
          field = "externalTools.tools.crush.available";
          expected = true;
        }
      ];
    }
  ];

  # PERFORMANCE BDD TESTS
  PerformanceTests = systemConfig: [
    {
      scenario = "Wrapper Performance Within Limits";
      given = {
        wrapper = {
          name = "test-wrapper";
          type = "cli-tool";
          performance = {
            maxMemory = 256;
            maxDuration = 10;
          };
        };
        system = systemConfig;
      };
      when = [
        { name = "Create performance monitor"; action = "createPerformanceMonitor"; }
        { name = "Execute wrapper"; action = "executeWrapper"; }
        { name = "Monitor performance"; action = "monitorPerformance"; }
      ];
      then = [];
      expectations = [
        {
          description = "Memory usage should be within limits";
          field = "performance.memoryValid";
          expected = true;
        }
        {
          description = "Execution time should be within limits";
          field = "performance.durationValid";
          expected = true;
        }
      ];
    }
    {
      scenario = "System Resource Management";
      given = {
        system = systemConfig;
        performance = {
          maxMemory = 4096;
          maxConcurrentBuilds = 4;
        };
      };
      when = [
        { name = "Monitor system resources"; action = "monitorResources"; }
        { name = "Execute multiple wrappers"; action = "executeMultipleWrappers"; }
      ];
      then = [];
      expectations = [
        {
          description = "System should not exceed memory limits";
          field = "systemResource.withinLimits";
          expected = true;
        }
      ];
    }
  ];

  # INTEGRATION BDD TESTS
  IntegrationTests = systemConfig: [
    {
      scenario = "End-to-End Wrapper System";
      given = {
        system = systemConfig;
        wrappers = [
          {
            name = "starship-test";
            type = "cli-tool";
            package = pkgs.starship;
          }
          {
            name = "fish-test";
            type = "shell";
            package = pkgs.fish;
          }
        ];
      };
      when = [
        { name = "Generate all wrappers"; action = "generateAllWrappers"; }
        { name = "Build all wrappers"; action = "buildAllWrappers"; }
        { name = "Install all wrappers"; action = "installAllWrappers"; }
      ];
      then = [];
      expectations = [
        {
          description = "All wrappers should be generated";
          field = "wrapperGeneration.allGenerated";
          expected = true;
        }
        {
          description = "All wrappers should be built";
          field = "wrapperBuild.allSuccessful";
          expected = true;
        }
        {
          description = "All wrappers should be installed";
          field = "wrapperInstall.allSuccessful";
          expected = true;
        }
      ];
    }
    {
      scenario = "Rollback on Failure";
      given = {
        system = systemConfig;
        failingWrapper = {
          name = "failing-wrapper";
          type = "cli-tool";
          package = null; # Intentionally invalid
        };
      };
      when = [
        { name = "Attempt wrapper generation"; action = "generateWrapper"; }
        { name = "Detect failure"; action = "detectFailure"; }
        { name = "Perform rollback"; action = "rollback"; }
      ];
      then = [];
      expectations = [
        {
          description = "System should detect failure";
          field = "rollback.failureDetected";
          expected = true;
        }
        {
          description = "System should rollback to previous state";
          field = "rollback.successful";
          expected = true;
        }
      ];
    }
  ];

  # COMPREHENSIVE TEST EXECUTION
  RunAllTests = systemConfig:
    let
      wrapperTests = BDDTestRunner {
        tests = WrapperSystemTests systemConfig;
        systemConfig = systemConfig;
      };

      perfTests = BDDTestRunner {
        tests = PerformanceTests systemConfig;
        systemConfig = systemConfig;
      };

      integrationTests = BDDTestRunner {
        tests = IntegrationTests systemConfig;
        systemConfig = systemConfig;
      };

      allTestResults = [
        { name = "Wrapper System"; results = wrapperTests; }
        { name = "Performance"; results = perfTests; }
        { name = "Integration"; results = integrationTests; }
      ];

      totalTests = wrapperTests.total + perfTests.total + integrationTests.total;
      totalPassed = (builtins.length wrapperTests.passed) + (builtins.length perfTests.passed) + (builtins.length integrationTests.passed);
      totalFailed = totalTests - totalPassed;

      overallPassRate = totalPassed * 100.0 / totalTests;
      overallSuccess = totalFailed == 0;

    in {
      testSuites = allTestResults;
      totalTests = totalTests;
      totalPassed = totalPassed;
      totalFailed = totalFailed;
      passRate = overallPassRate;
      success = overallSuccess;
      summary = {
        wrapperSystem = wrapperTests;
        performance = perfTests;
        integration = integrationTests;
      };
    };

in {
  inherit BDDTestRunner WrapperSystemTests PerformanceTests IntegrationTests RunAllTests;
}
