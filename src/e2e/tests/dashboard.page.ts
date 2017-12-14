import {browser, by, element} from 'protractor';
import {promise} from "selenium-webdriver";
import Promise = promise.Promise;

import {Urls} from "../urls";
import {App} from "./app";

export class DashboardPage extends App {
    navigateTo() {
        return browser.get(Urls.APP_BASE_URL + "dashboard");
    }
}